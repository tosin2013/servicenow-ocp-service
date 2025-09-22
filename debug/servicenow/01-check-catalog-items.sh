#!/bin/bash
#
# Debug Script 1: Check ServiceNow Catalog Items
# Validates that OpenShift catalog items exist in ServiceNow
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

print_header "ServiceNow Catalog Items Debug"

print_step "Step 1: Check All Active Catalog Items"
echo "Querying: ${SERVICENOW_URL}/api/now/table/sc_cat_item?sysparm_query=active=true"

TOTAL_ITEMS=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sc_cat_item?sysparm_query=active=true&sysparm_fields=sys_id" \
  | jq '.result | length')

if [ "$TOTAL_ITEMS" -gt 0 ]; then
    print_success "Found $TOTAL_ITEMS active catalog items"
else
    print_error "No active catalog items found"
    exit 1
fi

print_step "Step 2: Check OpenShift-Specific Catalog Items"
echo "Querying: ${SERVICENOW_URL}/api/now/table/sc_cat_item?sysparm_query=nameLIKEOpenShift"

OPENSHIFT_ITEMS=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sc_cat_item?sysparm_query=nameLIKEOpenShift&sysparm_fields=name,sys_id,active,sys_created_on" \
  | jq -r '.result[]')

if [ -n "$OPENSHIFT_ITEMS" ]; then
    print_success "Found OpenShift catalog items:"
    curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
      -H "Accept: application/json" \
      "${SERVICENOW_URL}/api/now/table/sc_cat_item?sysparm_query=nameLIKEOpenShift&sysparm_fields=name,sys_id,active,sys_created_on" \
      | jq -r '.result[] | "  • \(.name) (ID: \(.sys_id)) - Active: \(.active) - Created: \(.sys_created_on)"'
else
    print_error "No OpenShift catalog items found"
fi

print_step "Step 3: Check Recent Catalog Requests"
echo "Querying recent requests from last 24 hours..."

RECENT_REQUESTS=$(curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sc_request?sysparm_query=sys_created_onONToday@javascript:gs.daysAgoStart(1)@javascript:gs.daysAgoEnd(0)&sysparm_fields=number,short_description,request_state,sys_created_on&sysparm_limit=10" \
  | jq '.result | length')

if [ "$RECENT_REQUESTS" -gt 0 ]; then
    print_success "Found $RECENT_REQUESTS recent requests:"
    curl -s -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
      -H "Accept: application/json" \
      "${SERVICENOW_URL}/api/now/table/sc_request?sysparm_query=sys_created_onONToday@javascript:gs.daysAgoStart(1)@javascript:gs.daysAgoEnd(0)&sysparm_fields=number,short_description,request_state,sys_created_on&sysparm_limit=10" \
      | jq -r '.result[] | "  • \(.number): \(.short_description) - State: \(.request_state) - Created: \(.sys_created_on)"'
else
    print_info "No recent requests found in last 24 hours"
fi

print_step "Step 4: Test ServiceNow API Authentication"
AUTH_TEST=$(curl -s -w "%{http_code}" -o /dev/null -u "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
  -H "Accept: application/json" \
  "${SERVICENOW_URL}/api/now/table/sys_user?sysparm_limit=1")

if [ "$AUTH_TEST" = "200" ]; then
    print_success "ServiceNow API authentication successful"
else
    print_error "ServiceNow API authentication failed (HTTP: $AUTH_TEST)"
fi

print_header "ServiceNow Debug Summary"
echo -e "${CYAN}• Total Catalog Items: $TOTAL_ITEMS${NC}"
echo -e "${CYAN}• Recent Requests: $RECENT_REQUESTS${NC}"
echo -e "${CYAN}• API Status: HTTP $AUTH_TEST${NC}"
echo -e "${CYAN}• ServiceNow URL: $SERVICENOW_URL${NC}"
