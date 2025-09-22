#!/bin/bash
#
# 🔍 ServiceNow Monitoring Utility - SECURE VERSION
# Real-time monitoring of ServiceNow requests and incidents
# Uses vault configuration for credentials
#

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source vault configuration securely
if [ ! -f "$PROJECT_ROOT/.vault_pass" ]; then
    echo "❌ Error: Vault password file not found at $PROJECT_ROOT/.vault_pass"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/ansible/group_vars/all/vault.yml" ]; then
    echo "❌ Error: Vault file not found at $PROJECT_ROOT/ansible/group_vars/all/vault.yml"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

# Decrypt vault and source variables
VAULT_TEMP=$(mktemp)
trap "rm -f $VAULT_TEMP" EXIT

if ! ansible-vault view "$PROJECT_ROOT/ansible/group_vars/all/vault.yml" \
    --vault-password-file "$PROJECT_ROOT/.vault_pass" > "$VAULT_TEMP" 2>/dev/null; then
    echo "❌ Error: Failed to decrypt vault file"
    echo "Please check your vault password and file integrity."
    exit 1
fi

# Source the decrypted vault variables
source "$VAULT_TEMP"

# Validate required variables
if [ -z "${servicenow_url:-}" ] || [ -z "${servicenow_username:-}" ] || [ -z "${vault_servicenow_password:-}" ]; then
    echo "❌ Error: Required ServiceNow configuration not found in vault"
    echo "Please ensure servicenow_url, servicenow_username, and vault_servicenow_password are configured."
    exit 1
fi

# Configuration from vault
SERVICENOW_URL="$servicenow_url"
SERVICENOW_USER="$servicenow_username"
SERVICENOW_PASS="$vault_servicenow_password"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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

call_servicenow_api() {
    local method="$1"
    local endpoint="$2"
    
    if ! curl -s -k --user "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
         -X "$method" \
         -H "Accept: application/json" \
         "${SERVICENOW_URL}${endpoint}" 2>/dev/null; then
        print_error "Failed to call ServiceNow API: $endpoint"
        return 1
    fi
}

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

monitor_request() {
    local req_number="$1"
    
    print_header "🔍 ServiceNow Request: $req_number"
    
    if ! test_servicenow_connection; then
        return 1
    fi
    
    local response
    if response=$(call_servicenow_api "GET" "/api/now/table/sc_request?sysparm_query=number=$req_number"); then
        echo "$response" | jq -r '
            .result[] | 
            "Request Number: \(.number)",
            "State: \(.state)",
            "Stage: \(.stage)",
            "Approval: \(.approval)",
            "Requested For: \(.requested_for.display_value)",
            "Short Description: \(.short_description)",
            "Created: \(.sys_created_on)",
            "Updated: \(.sys_updated_on)"
        ' | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
        
        # Check for related requested items
        print_info "Checking related requested items..."
        if response=$(call_servicenow_api "GET" "/api/now/table/sc_req_item?sysparm_query=request.number=$req_number"); then
            echo "$response" | jq -r '
                .result[] | 
                "Item: \(.cat_item.display_value)",
                "State: \(.state)",
                "Stage: \(.stage)",
                "Work Notes: \(.work_notes)"
            ' | while read -r line; do
                echo -e "${YELLOW}  $line${NC}"
            done
        fi
    else
        print_error "Failed to retrieve request details for $req_number"
        return 1
    fi
}

monitor_incidents() {
    local search_term="${1:-OpenShift}"
    
    print_header "🔍 ServiceNow Incidents (Search: $search_term)"
    
    if ! test_servicenow_connection; then
        return 1
    fi
    
    local response
    if response=$(call_servicenow_api "GET" "/api/now/table/incident?sysparm_query=short_descriptionLIKE$search_term&sysparm_limit=10"); then
        echo "$response" | jq -r '
            .result[] | 
            "\(.number) | \(.state) | \(.short_description) | \(.sys_created_on)"
        ' | while IFS='|' read -r number state description created; do
            case "$state" in
                "1")
                    echo -e "${BLUE}🆕 $number: New${NC}"
                    ;;
                "2")
                    echo -e "${YELLOW}🔄 $number: In Progress${NC}"
                    ;;
                "6")
                    echo -e "${GREEN}✅ $number: Resolved${NC}"
                    ;;
                "7")
                    echo -e "${GREEN}✅ $number: Closed${NC}"
                    ;;
                *)
                    echo -e "${CYAN}ℹ️  $number: State $state${NC}"
                    ;;
            esac
            echo -e "   Description: $description"
            echo -e "   Created: $created"
            echo ""
        done
    else
        print_error "Failed to retrieve incidents"
        return 1
    fi
}

monitor_all_requests() {
    print_header "🔍 Recent ServiceNow Requests"
    
    if ! test_servicenow_connection; then
        return 1
    fi
    
    local response
    if response=$(call_servicenow_api "GET" "/api/now/table/sc_request?sysparm_limit=10&sysparm_query=ORDERBYDESCsys_created_on"); then
        echo "$response" | jq -r '
            .result[] | 
            "\(.number) | \(.state) | \(.short_description) | \(.sys_created_on)"
        ' | while IFS='|' read -r number state description created; do
            case "$state" in
                "1")
                    echo -e "${BLUE}🆕 $number: Requested${NC}"
                    ;;
                "2")
                    echo -e "${YELLOW}🔄 $number: In Process${NC}"
                    ;;
                "3")
                    echo -e "${GREEN}✅ $number: Completed${NC}"
                    ;;
                *)
                    echo -e "${CYAN}ℹ️  $number: State $state${NC}"
                    ;;
            esac
            echo -e "   Description: $description"
            echo -e "   Created: $created"
            echo ""
        done
    else
        print_error "Failed to retrieve requests"
        return 1
    fi
}

watch_mode() {
    local req_number="$1"
    local interval="${2:-10}"
    
    print_header "👀 Watching ServiceNow Request: $req_number (Refresh every ${interval}s)"
    print_info "Press Ctrl+C to stop watching"
    
    while true; do
        clear
        monitor_request "$req_number"
        echo -e "\n${YELLOW}Refreshing in ${interval} seconds...${NC}"
        sleep "$interval"
    done
}

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  request <REQ_NUMBER>     Monitor specific request"
    echo "  incidents [SEARCH_TERM]  Show incidents (default: OpenShift)"
    echo "  requests                 Show recent requests"
    echo "  watch <REQ_NUMBER> [INTERVAL] Watch request in real-time"
    echo "  test                     Test ServiceNow connection"
    echo ""
    echo "Examples:"
    echo "  $0 request REQ0010044"
    echo "  $0 incidents OpenShift"
    echo "  $0 requests"
    echo "  $0 watch REQ0010044 5"
    echo "  $0 test"
}

main() {
    case "${1:-}" in
        "request")
            if [ $# -lt 2 ]; then
                echo "Error: Request number required"
                usage
                exit 1
            fi
            monitor_request "$2"
            ;;
        "incidents")
            monitor_incidents "${2:-OpenShift}"
            ;;
        "requests")
            monitor_all_requests
            ;;
        "watch")
            if [ $# -lt 2 ]; then
                echo "Error: Request number required for watch mode"
                usage
                exit 1
            fi
            watch_mode "$2" "${3:-10}"
            ;;
        "test")
            test_servicenow_connection
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
