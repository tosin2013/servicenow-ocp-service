#!/bin/bash
#
# Debug Script 1: Check AAP Connectivity and Job Templates
# Validates AAP API access and available job templates
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

# Configuration - Get AAP token from vault
AAP_URL="https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# Get AAP token from vault
print_info "Getting AAP token from vault..."
cd "$PROJECT_ROOT"
AAP_TOKEN=$(ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep vault_aap_token | cut -d'"' -f2)

if [ -z "$AAP_TOKEN" ]; then
    print_error "Could not retrieve AAP token from vault"
    exit 1
fi

print_header "AAP Connectivity Debug"

print_step "Step 1: Test AAP API Authentication"
AUTH_TEST=$(curl -s -w "%{http_code}" -o /dev/null \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/me/")

if [ "$AUTH_TEST" = "200" ]; then
    print_success "AAP API authentication successful"
else
    print_error "AAP API authentication failed (HTTP: $AUTH_TEST)"
    exit 1
fi

print_step "Step 2: Get AAP User Info"
USER_INFO=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/me/")

echo "$USER_INFO" | jq -r '"  • Username: \(.username)
  • First Name: \(.first_name)
  • Last Name: \(.last_name)
  • Email: \(.email)
  • Is Superuser: \(.is_superuser)"'

print_step "Step 3: List Available Job Templates"
JOB_TEMPLATES=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/job_templates/")

TEMPLATE_COUNT=$(echo "$JOB_TEMPLATES" | jq '.count')
print_success "Found $TEMPLATE_COUNT job templates:"

echo "$JOB_TEMPLATES" | jq -r '.results[] | "  • ID: \(.id) - Name: \(.name) - Playbook: \(.playbook)"'

print_step "Step 4: Check Specific OpenShift Job Template (ID: 9)"
OPENSHIFT_TEMPLATE=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/job_templates/9/")

if echo "$OPENSHIFT_TEMPLATE" | jq -e '.id' > /dev/null; then
    print_success "OpenShift job template found:"
    echo "$OPENSHIFT_TEMPLATE" | jq -r '"  • ID: \(.id)
  • Name: \(.name)
  • Description: \(.description)
  • Playbook: \(.playbook)
  • Project: \(.project)
  • Inventory: \(.inventory)
  • Enabled: \(.enabled)"'
else
    print_error "OpenShift job template (ID: 9) not found"
    echo "$OPENSHIFT_TEMPLATE" | jq '.'
fi

print_step "Step 5: Check Recent Job Executions"
RECENT_JOBS=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/jobs/?page_size=5&order_by=-created")

JOB_COUNT=$(echo "$RECENT_JOBS" | jq '.count')
print_info "Total jobs in system: $JOB_COUNT"
print_info "Recent 5 jobs:"

echo "$RECENT_JOBS" | jq -r '.results[] | "  • Job \(.id): \(.name) - Status: \(.status) - Created: \(.created)"'

print_step "Step 6: Check AAP System Status"
SYSTEM_STATUS=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/ping/")

echo "$SYSTEM_STATUS" | jq -r '"  • Version: \(.version)
  • Active Node: \(.active_node)
  • Install UUID: \(.install_uuid)"'

print_header "AAP Debug Summary"
echo -e "${CYAN}• AAP URL: $AAP_URL${NC}"
echo -e "${CYAN}• API Status: HTTP $AUTH_TEST${NC}"
echo -e "${CYAN}• Job Templates: $TEMPLATE_COUNT${NC}"
echo -e "${CYAN}• Total Jobs: $JOB_COUNT${NC}"
