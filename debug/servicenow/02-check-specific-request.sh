#!/bin/bash
#
# Debug Script 2: Check Specific ServiceNow Request
# Usage: ./02-check-specific-request.sh [REQUEST_ID]
# Example: ./02-check-specific-request.sh e522a7b547c03e50292cc82f316d43ec
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

# Configuration - Get credentials from vault
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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
if [ -z "${servicenow_url:-}" ] || [ -z "${vault_servicenow_user:-}" ] || [ -z "${vault_servicenow_password:-}" ]; then
    echo "❌ Error: Required ServiceNow configuration not found in vault"
    echo "Please ensure servicenow_url, vault_servicenow_user, and vault_servicenow_password are configured."
    exit 1
fi

# Configuration from vault
SERVICENOW_URL="$servicenow_url"
SERVICENOW_USER="$vault_servicenow_user"
SERVICENOW_PASS="$vault_servicenow_password"

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_step() {
    echo -e "\n${BOLD}${CYAN}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Get request ID from command line or use the most recent one
REQUEST_ID="${1:-}"

if [ -z "$REQUEST_ID" ]; then
    print_info "No request ID provided, finding most recent request..."
    REQUEST_ID=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
      -H "Accept: application/json" \
      "${SERVICENOW_URL}/api/now/table/sc_request?sysparm_query=ORDERBYDESCsys_created_on&sysparm_limit=1&sysparm_fields=sys_id" \
      | jq -r '.result[0].sys_id')
    
    if [ "$REQUEST_ID" = "null" ] || [ -z "$REQUEST_ID" ]; then
        print_error "Could not find any requests"
        exit 1
    fi
    print_info "Using most recent request: $REQUEST_ID"
fi

print_header "ServiceNow Request Debug: $REQUEST_ID"

print_step "Step 1: Get Request Details"
REQUEST_DATA=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sc_request/${REQUEST_ID}")

if echo "$REQUEST_DATA" | jq -e '.result' > /dev/null; then
    print_success "Request found"
    echo "$REQUEST_DATA" | jq -r '.result | "  • Number: \(.number)
  • Short Description: \(.short_description)
  • State: \(.request_state)
  • Stage: \(.stage)
  • Approval: \(.approval)
  • Created: \(.sys_created_on)
  • Updated: \(.sys_updated_on)"'
else
    print_error "Request not found or API error"
    echo "$REQUEST_DATA" | jq '.'
    exit 1
fi

print_step "Step 2: Get Request Items"
REQ_ITEMS=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sc_req_item?sysparm_query=request=${REQUEST_ID}")

ITEM_COUNT=$(echo "$REQ_ITEMS" | jq '.result | length')
if [ "$ITEM_COUNT" -gt 0 ]; then
    print_success "Found $ITEM_COUNT request items:"
    echo "$REQ_ITEMS" | jq -r '.result[] | "  • \(.number): \(.short_description) - State: \(.state)"'
else
    print_info "No request items found (direct request, not catalog-based)"
fi

print_step "Step 3: Get Request Variables/Custom Fields"
echo "$REQUEST_DATA" | jq -r '.result.description' | head -10

print_step "Step 4: Check Work Notes and Comments"
WORK_NOTES=$(echo "$REQUEST_DATA" | jq -r '.result.work_notes // empty')
COMMENTS=$(echo "$REQUEST_DATA" | jq -r '.result.comments // empty')

if [ -n "$WORK_NOTES" ]; then
    print_info "Work Notes:"
    echo "$WORK_NOTES"
else
    print_info "No work notes"
fi

if [ -n "$COMMENTS" ]; then
    print_info "Comments:"
    echo "$COMMENTS"
else
    print_info "No comments"
fi

print_step "Step 5: Check Request State History"
# This would require additional API calls to sys_audit table
print_info "Request state progression tracking would require sys_audit table access"

print_header "Request Debug Summary"
REQUEST_NUMBER=$(echo "$REQUEST_DATA" | jq -r '.result.number')
REQUEST_STATE=$(echo "$REQUEST_DATA" | jq -r '.result.request_state')
echo -e "${CYAN}• Request Number: $REQUEST_NUMBER${NC}"
echo -e "${CYAN}• Request State: $REQUEST_STATE${NC}"
echo -e "${CYAN}• Request Items: $ITEM_COUNT${NC}"
echo -e "${CYAN}• Request ID: $REQUEST_ID${NC}"
