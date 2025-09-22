#!/bin/bash
#
# 🎓 Beginner OpenShift Project Creation Workflow - SECURE VERSION
# Step-by-step guided process with manual interactions and Ansible integration
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
if [ -z "${servicenow_url:-}" ] || [ -z "${aap_url:-}" ]; then
    echo "❌ Error: Required configuration not found in vault"
    echo "Please ensure servicenow_url and aap_url are configured in your vault file."
    exit 1
fi

# Configuration from vault
SERVICENOW_URL="$servicenow_url"
AAP_URL="$aap_url"
ENABLE_ANSIBLE_DEMOS=true

# Source common Ansible integration functions
if [ -f "$SCRIPT_DIR/../common/ansible-integration.sh" ]; then
    source "$SCRIPT_DIR/../common/ansible-integration.sh"
else
    echo "⚠️  Warning: ansible-integration.sh not found, some features may be limited"
fi

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
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_step() {
    echo -e "\n${BOLD}${CYAN}📋 Step $1: $2${NC}"
}

print_action() {
    echo -e "${YELLOW}👉 ACTION REQUIRED:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

print_wait() {
    echo -e "${YELLOW}⏳ WAITING:${NC} $1"
}

print_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

# Function to open URLs (if available)
open_url() {
    local url="$1"
    local description="$2"
    
    print_info "Opening: $description"
    print_info "URL: $url"
    
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" 2>/dev/null || true
    elif command -v open >/dev/null 2>&1; then
        open "$url" 2>/dev/null || true
    else
        print_info "Please manually open the URL above in your browser"
    fi
}

# Function to wait for user input
wait_for_user() {
    echo ""
    read -p "Press Enter to continue when ready..."
}

# Function to validate request number format
validate_request_number() {
    local req_number="$1"
    if [[ ! "$req_number" =~ ^REQ[0-9]{7}$ ]]; then
        print_error "Invalid request number format. Expected: REQ0000000"
        return 1
    fi
    return 0
}

# Main workflow function
run_beginner_workflow() {
    print_header "🎓 Beginner OpenShift Project Creation Workflow"
    echo -e "${CYAN}This workflow will guide you through creating an OpenShift project via ServiceNow${NC}"
    echo -e "${CYAN}Using secure vault configuration for all credentials${NC}"
    echo ""
    
    print_info "Configuration loaded from vault:"
    echo -e "  ${CYAN}• ServiceNow URL:${NC} $SERVICENOW_URL"
    echo -e "  ${CYAN}• AAP URL:${NC} $AAP_URL"
    echo ""
    
    # Step 1: Create ServiceNow Request
    print_step "1" "Create ServiceNow Request"
    echo ""
    print_info "We'll create a ServiceNow catalog request for an OpenShift project."
    echo ""
    print_info "Suggested project details:"
    echo -e "  ${CYAN}• Project Name:${NC} my-beginner-project"
    echo -e "  ${CYAN}• Environment:${NC} development"
    echo -e "  ${CYAN}• Display Name:${NC} My Beginner Project"
    echo -e "  ${CYAN}• Business Justification:${NC} Learning workflow process"
    echo ""
    
    open_url "$SERVICENOW_URL/sp?id=sc_home" "ServiceNow Service Catalog"
    
    echo ""
    print_info "Navigation steps:"
    echo -e "1. Search for ${CYAN}'OpenShift'${NC} in the catalog"
    echo -e "2. Select ${CYAN}'OpenShift Project Request'${NC}"
    echo -e "3. Fill in the project details as suggested above"
    echo -e "4. Submit the request"
    echo ""
    
    wait_for_user
    
    print_action "Please enter the ServiceNow request number (e.g., REQ0010025):"
    local req_number
    while true; do
        read -p "Request Number: " req_number
        if validate_request_number "$req_number"; then
            break
        fi
        print_error "Please enter a valid request number in format REQ0000000"
    done
    
    print_success "Request number captured: $req_number"
    
    # Step 2: Approve Workflow
    print_step "2" "Approve ServiceNow Request"
    echo ""
    print_info "Now we'll approve the ServiceNow request to trigger the AAP workflow."
    echo ""
    
    wait_for_user
    
    print_info "Running secure approval script..."
    if [ -f "$PROJECT_ROOT/approve_workflow_secure.sh" ]; then
        if "$PROJECT_ROOT/approve_workflow_secure.sh" "$req_number"; then
            print_success "Request approved successfully"
        else
            print_error "Approval failed. Please check the error messages above."
            exit 1
        fi
    else
        print_error "Secure approval script not found at $PROJECT_ROOT/approve_workflow_secure.sh"
        print_info "Please ensure the secure approval script is available."
        exit 1
    fi
    
    # Step 3: Monitor ServiceNow Progress
    print_step "3" "Monitor ServiceNow Progress"
    echo ""
    print_info "Let's check the ServiceNow request and incident for updates."
    echo ""
    
    open_url "$SERVICENOW_URL/nav_to.do?uri=sc_request_list.do" "ServiceNow Requests"
    
    print_action "Please check the following in ServiceNow:"
    echo -e "1. ${CYAN}Find your request${NC} ($req_number) in the list"
    echo -e "2. ${CYAN}Check the work notes${NC} for AAP job information"
    echo -e "3. ${CYAN}Look for a tracking incident${NC} (INC number)"
    echo ""
    
    wait_for_user
    
    print_action "Please enter the incident number (if created):"
    read -p "INC Number (or press Enter to skip): " inc_number
    
    if [[ -n "$inc_number" ]]; then
        print_success "Tracking incident: $inc_number"
        open_url "$SERVICENOW_URL/nav_to.do?uri=incident_list.do" "ServiceNow Incidents"
    fi
    
    # Step 4: Monitor AAP
    print_step "4" "Monitor Ansible Automation Platform"
    echo ""
    print_info "Now let's check the AAP job execution."
    echo ""
    
    open_url "$AAP_URL/#/jobs" "AAP Jobs Dashboard"
    
    print_action "Please check the following in AAP:"
    echo -e "1. ${CYAN}Look for the newest job${NC} in the jobs list"
    echo -e "2. ${CYAN}Click on the job${NC} to see details"
    echo -e "3. ${CYAN}Check the job status${NC} (Running/Successful/Failed)"
    echo -e "4. ${CYAN}Review the job output${NC} for any errors"
    echo ""
    
    wait_for_user
    
    print_action "Please enter the AAP job ID (if available):"
    read -p "Job ID (or press Enter to skip): " job_id
    
    if [[ -n "$job_id" ]]; then
        print_success "AAP Job ID: $job_id"
        
        # Use secure monitoring script if available
        if [ -f "$SCRIPT_DIR/../common/monitor-aap-secure.sh" ]; then
            print_info "Using secure AAP monitoring script..."
            "$SCRIPT_DIR/../common/monitor-aap-secure.sh" job "$job_id"
        fi
    fi
    
    # Step 5: Verify OpenShift Project
    print_step "5" "Verify OpenShift Project Creation"
    echo ""
    print_info "Finally, let's verify that the OpenShift project was created successfully."
    echo ""
    
    print_action "Please check the following:"
    echo -e "1. ${CYAN}Log into OpenShift console${NC}"
    echo -e "2. ${CYAN}Look for your project${NC} (my-beginner-project)"
    echo -e "3. ${CYAN}Verify project permissions${NC}"
    echo -e "4. ${CYAN}Check project resources${NC} (quotas, network policies, etc.)"
    echo ""
    
    wait_for_user
    
    # Final Summary
    print_header "🎉 Workflow Complete!"
    echo ""
    print_success "Beginner workflow completed successfully!"
    echo ""
    print_info "Summary:"
    echo -e "  ${CYAN}• ServiceNow Request:${NC} $req_number"
    if [[ -n "${inc_number:-}" ]]; then
        echo -e "  ${CYAN}• Tracking Incident:${NC} $inc_number"
    fi
    if [[ -n "${job_id:-}" ]]; then
        echo -e "  ${CYAN}• AAP Job ID:${NC} $job_id"
    fi
    echo -e "  ${CYAN}• Project Name:${NC} my-beginner-project"
    echo ""
    print_info "Next steps:"
    echo -e "1. ${CYAN}Explore your OpenShift project${NC}"
    echo -e "2. ${CYAN}Try the advanced workflow${NC} for more automation"
    echo -e "3. ${CYAN}Review the documentation${NC} for additional features"
    echo ""
}

# Usage function
usage() {
    echo "Usage: $0"
    echo ""
    echo "This script provides a guided beginner workflow for creating OpenShift projects"
    echo "through ServiceNow integration using secure vault configuration."
    echo ""
    echo "Prerequisites:"
    echo "  - Vault configuration completed (vault.yml and .vault_pass)"
    echo "  - Access to ServiceNow and AAP instances"
    echo "  - approve_workflow_secure.sh script available"
}

# Main execution
main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        usage
        exit 0
    fi
    
    run_beginner_workflow
}

main "$@"
