#!/bin/bash
#
# 🔍 Show Test Request Information
# Quick script to display the current test request details
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_CMD_BASE="./run_playbook.sh"
VAULT_ARGS="-e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout"

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Create a simple playbook to get current test request info
create_info_playbook() {
    cat > /tmp/show_request_info.yml << 'EOF'
---
- name: Show Current Test Request Information
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    test_display_name: "E2E Test Project - Idempotent"

  tasks:
    - name: Find current test request
      uri:
        url: "{{ servicenow_url }}/api/now/table/sc_request"
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        method: GET
        force_basic_auth: yes
        validate_certs: false
        headers:
          Accept: "application/json"
        status_code: 200
      register: current_request
      vars:
        query_params:
          sysparm_query: "short_description={{ test_display_name }}"
          sysparm_fields: "sys_id,number,short_description,state,sys_created_on"
          sysparm_limit: 1

    - name: Find current test requested item
      uri:
        url: "{{ servicenow_url }}/api/now/table/sc_req_item"
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        method: GET
        force_basic_auth: yes
        validate_certs: false
        headers:
          Accept: "application/json"
        status_code: 200
      register: current_req_item
      vars:
        query_params:
          sysparm_query: "request={{ current_request.json.result[0].sys_id if current_request.json.result|length > 0 else 'none' }}"
          sysparm_fields: "sys_id,number,short_description,state,u_aap_job_id,u_aap_job_status"
          sysparm_limit: 1
      when: current_request.json.result|length > 0

    - name: Display current test request information
      debug:
        msg: |
          🔍 CURRENT TEST REQUEST INFORMATION
          
          {% if current_request.json.result|length > 0 %}
          📋 Request Details:
          - Request Number: {{ current_request.json.result[0].number }}
          - Request ID: {{ current_request.json.result[0].sys_id }}
          - Description: {{ current_request.json.result[0].short_description }}
          - State: {{ current_request.json.result[0].state }}
          - Created: {{ current_request.json.result[0].sys_created_on }}
          
          {% if current_req_item.json.result|length > 0 %}
          📦 Requested Item Details:
          - Item Number: {{ current_req_item.json.result[0].number }}
          - Item ID: {{ current_req_item.json.result[0].sys_id }}
          - Description: {{ current_req_item.json.result[0].short_description }}
          - State: {{ current_req_item.json.result[0].state }}
          - AAP Job ID: {{ current_req_item.json.result[0].u_aap_job_id | default('Not set') }}
          - AAP Job Status: {{ current_req_item.json.result[0].u_aap_job_status | default('Not set') }}
          {% endif %}
          
          🔗 ServiceNow URLs:
          - Request: {{ servicenow_url }}/nav_to.do?uri=sc_request.do?sys_id={{ current_request.json.result[0].sys_id }}
          {% if current_req_item.json.result|length > 0 %}
          - Item: {{ servicenow_url }}/nav_to.do?uri=sc_req_item.do?sys_id={{ current_req_item.json.result[0].sys_id }}
          {% endif %}
          
          📊 Business Rules Status:
          {% if current_req_item.json.result|length > 0 and current_req_item.json.result[0].u_aap_job_id %}
          ✅ Business Rules executed - AAP Job ID: {{ current_req_item.json.result[0].u_aap_job_id }}
          - AAP Job URL: {{ aap_url }}/#/jobs/{{ current_req_item.json.result[0].u_aap_job_id }}
          {% else %}
          ❌ Business Rules not executed or no AAP job triggered
          {% endif %}
          
          💡 Dashboard Navigation:
          1. Go to ServiceNow: {{ servicenow_url }}
          2. Navigate to: Service Catalog > My Requests
          3. Look for: {{ current_request.json.result[0].number }}
          4. Check item state and AAP job details
          
          {% else %}
          ❌ No test request found with description: "{{ test_display_name }}"
          
          💡 To create a test request, run:
          ./scripts/clean_and_test_workflow.sh test
          {% endif %}
EOF
}

main() {
    clear
    print_header "🔍 Current Test Request Information"
    
    echo -e "\n${BOLD}ServiceNow Test Request Lookup${NC}"
    echo -e "Finding current idempotent test request details..."
    echo ""
    
    # Verify prerequisites
    if [ ! -f "$PROJECT_ROOT/run_playbook.sh" ]; then
        echo -e "${RED}❌ run_playbook.sh not found in project root${NC}"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/.vault_pass" ]; then
        echo -e "${RED}❌ .vault_pass not found in project root${NC}"
        exit 1
    fi
    
    print_success "Prerequisites verified"
    echo ""
    
    # Create temporary playbook
    create_info_playbook
    
    # Run the info playbook
    cd "$PROJECT_ROOT"
    
    print_info "Querying ServiceNow for current test request..."
    
    local cmd="$ANSIBLE_CMD_BASE /tmp/show_request_info.yml $VAULT_ARGS"
    
    if eval "$cmd"; then
        print_success "Request information retrieved successfully"
    else
        echo -e "${RED}❌ Failed to retrieve request information${NC}"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/show_request_info.yml
    
    echo ""
    print_info "Use the URLs above to check the request in ServiceNow dashboard"
}

# Show usage if help requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "🔍 Show Test Request Information"
    echo ""
    echo "This script queries ServiceNow to find the current idempotent test request"
    echo "and displays all relevant details including URLs for dashboard access."
    echo ""
    echo "Usage: $0"
    echo ""
    echo "The script will show:"
    echo "- Request number and ID"
    echo "- Requested item details"
    echo "- Business Rules execution status"
    echo "- AAP job information (if triggered)"
    echo "- Direct URLs to view in ServiceNow"
    echo ""
    exit 0
fi

main "$@"
