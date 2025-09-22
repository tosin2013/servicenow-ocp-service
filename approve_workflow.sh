#!/bin/bash
#
# 🔐 ServiceNow Workflow Approval Script - SECURE VERSION
# Approves ServiceNow requests and moves them through the workflow states
# Uses vault configuration for credentials
# Usage: ./approve_workflow_secure.sh REQ0010025
#

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source vault configuration securely
if [ ! -f "$SCRIPT_DIR/.vault_pass" ]; then
    echo "❌ Error: Vault password file not found at $SCRIPT_DIR/.vault_pass"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/ansible/group_vars/all/vault.yml" ]; then
    echo "❌ Error: Vault file not found at $SCRIPT_DIR/ansible/group_vars/all/vault.yml"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

# Decrypt vault and extract variables
VAULT_TEMP=$(mktemp)
trap "rm -f $VAULT_TEMP" EXIT

if ! ansible-vault view "$SCRIPT_DIR/ansible/group_vars/all/vault.yml" \
    --vault-password-file "$SCRIPT_DIR/.vault_pass" > "$VAULT_TEMP" 2>/dev/null; then
    echo "❌ Error: Failed to decrypt vault file"
    echo "Please check your vault password and file integrity."
    exit 1
fi

# Extract variables from YAML (simple approach)
SERVICENOW_URL_FROM_VAULT=$(grep "^servicenow_url:" "$VAULT_TEMP" | cut -d'"' -f2)
SERVICENOW_USER_FROM_VAULT=$(grep "^servicenow_username:" "$VAULT_TEMP" | cut -d'"' -f2)
SERVICENOW_PASS_FROM_VAULT=$(grep "^vault_servicenow_password:" "$VAULT_TEMP" | cut -d'"' -f2)

# Validate required variables
if [ -z "${SERVICENOW_URL_FROM_VAULT:-}" ] || [ -z "${SERVICENOW_USER_FROM_VAULT:-}" ] || [ -z "${SERVICENOW_PASS_FROM_VAULT:-}" ]; then
    echo "❌ Error: Required ServiceNow configuration not found in vault"
    echo "Please ensure servicenow_url, servicenow_username, and vault_servicenow_password are configured."
    echo "Debug: SERVICENOW_URL_FROM_VAULT='${SERVICENOW_URL_FROM_VAULT:-}'"
    echo "Debug: SERVICENOW_USER_FROM_VAULT='${SERVICENOW_USER_FROM_VAULT:-}'"
    exit 1
fi

# Configuration from vault
SERVICENOW_URL="$SERVICENOW_URL_FROM_VAULT"
SERVICENOW_USER="$SERVICENOW_USER_FROM_VAULT"
SERVICENOW_PASS="$SERVICENOW_PASS_FROM_VAULT"

# OpenShift Catalog Item IDs (these should also be in vault for production)
OPENSHIFT_BASIC_CATALOG_ID="${openshift_basic_catalog_id:-1a3b56b1470cfa50292cc82f316d4378}"
OPENSHIFT_DATABASE_CATALOG_ID="${openshift_database_catalog_id:-aa3b1e75470cfa50292cc82f316d43e2}"

# Workflow Configuration
TARGET_STATE="2"  # 2 = Work in Progress
ENABLE_DEBUG="${enable_debug:-True}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to make ServiceNow API calls
call_servicenow_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    local curl_args=(
        -s -k
        --user "${SERVICENOW_USER}:${SERVICENOW_PASS}"
        -X "$method"
        -H "Accept: application/json"
        -H "Content-Type: application/json"
    )
    
    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi
    
    if ! curl "${curl_args[@]}" "${SERVICENOW_URL}${endpoint}" 2>/dev/null; then
        print_error "Failed to call ServiceNow API: $endpoint"
        return 1
    fi
}

# Function to test ServiceNow connection
test_servicenow_connection() {
    print_info "Testing ServiceNow connection..."
    
    if call_servicenow_api "GET" "/api/now/table/sys_user?sysparm_limit=1" >/dev/null; then
        print_success "ServiceNow connection successful"
        return 0
    else
        print_error "ServiceNow connection failed"
        print_info "Please check:"
        print_info "  - ServiceNow URL: $SERVICENOW_URL"
        print_info "  - Username: $SERVICENOW_USER"
        print_info "  - Password validity"
        print_info "  - Network connectivity"
        return 1
    fi
}

# Function to get request details
get_request_details() {
    local req_number="$1"
    
    print_info "Retrieving request details for $req_number..."
    
    local response
    if response=$(call_servicenow_api "GET" "/api/now/table/sc_request?sysparm_query=number=$req_number"); then
        echo "$response" | jq -r '.result[0] // empty'
    else
        print_error "Failed to retrieve request details"
        return 1
    fi
}

# Function to update request state
update_request_state() {
    local req_sys_id="$1"
    local new_state="$2"
    local work_notes="${3:-Approved via secure workflow script}"
    
    print_info "Updating request state to $new_state..."
    
    local update_data
    update_data=$(jq -n \
        --arg state "$new_state" \
        --arg notes "$work_notes" \
        '{
            "state": $state,
            "work_notes": $notes,
            "approval": "approved"
        }')
    
    if call_servicenow_api "PUT" "/api/now/table/sc_request/$req_sys_id" "$update_data" >/dev/null; then
        print_success "Request state updated successfully"
        return 0
    else
        print_error "Failed to update request state"
        return 1
    fi
}

# Function to approve request items
approve_request_items() {
    local req_number="$1"
    
    print_info "Approving request items for $req_number..."
    
    local response
    if response=$(call_servicenow_api "GET" "/api/now/table/sc_req_item?sysparm_query=request.number=$req_number"); then
        echo "$response" | jq -r '.result[] | .sys_id' | while read -r item_sys_id; do
            if [[ -n "$item_sys_id" ]]; then
                local item_update_data
                item_update_data=$(jq -n \
                    --arg state "$TARGET_STATE" \
                    '{
                        "state": $state,
                        "approval": "approved",
                        "work_notes": "Approved via secure workflow script - ready for AAP processing"
                    }')
                
                if call_servicenow_api "PUT" "/api/now/table/sc_req_item/$item_sys_id" "$item_update_data" >/dev/null; then
                    print_success "Request item $item_sys_id approved"
                else
                    print_error "Failed to approve request item $item_sys_id"
                fi
            fi
        done
    else
        print_error "Failed to retrieve request items"
        return 1
    fi
}

# Main approval function
approve_workflow() {
    local req_number="$1"
    
    print_header "🔐 Secure ServiceNow Workflow Approval"
    echo -e "Request Number: ${CYAN}$req_number${NC}"
    echo ""
    
    # Test connection first
    if ! test_servicenow_connection; then
        exit 1
    fi
    
    # Get request details
    local request_details
    if ! request_details=$(get_request_details "$req_number"); then
        exit 1
    fi
    
    if [[ -z "$request_details" ]]; then
        print_error "Request $req_number not found"
        exit 1
    fi
    
    # Extract request information
    local req_sys_id
    local current_state
    local short_description
    
    req_sys_id=$(echo "$request_details" | jq -r '.sys_id')
    current_state=$(echo "$request_details" | jq -r '.state')
    short_description=$(echo "$request_details" | jq -r '.short_description')
    
    print_info "Request Details:"
    echo -e "  ${CYAN}• Sys ID:${NC} $req_sys_id"
    echo -e "  ${CYAN}• Current State:${NC} $current_state"
    echo -e "  ${CYAN}• Description:${NC} $short_description"
    echo ""
    
    # Update request state
    if ! update_request_state "$req_sys_id" "$TARGET_STATE" "Approved via secure workflow script - moving to Work in Progress"; then
        exit 1
    fi
    
    # Approve request items
    if ! approve_request_items "$req_number"; then
        print_warning "Some request items may not have been approved properly"
    fi
    
    print_success "Workflow approval completed successfully!"
    print_info "Request $req_number is now in Work in Progress state"
    print_info "AAP job should be triggered automatically via Business Rules"
}

# Usage function
usage() {
    echo "Usage: $0 <REQUEST_NUMBER>"
    echo ""
    echo "Examples:"
    echo "  $0 REQ0010025"
    echo "  $0 REQ0010026"
    echo ""
    echo "This script securely approves ServiceNow requests using vault credentials."
    echo "Ensure vault configuration is properly set up before running."
}

# Main execution
main() {
    if [[ $# -ne 1 ]]; then
        print_error "Invalid number of arguments"
        usage
        exit 1
    fi
    
    local req_number="$1"
    
    # Validate request number format
    if [[ ! "$req_number" =~ ^REQ[0-9]{7}$ ]]; then
        print_error "Invalid request number format. Expected: REQ0000000"
        usage
        exit 1
    fi
    
    approve_workflow "$req_number"
}

main "$@"
