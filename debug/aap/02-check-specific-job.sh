#!/bin/bash
#
# Debug Script 2: Check Specific AAP Job
# Usage: ./02-check-specific-job.sh [JOB_ID]
# Example: ./02-check-specific-job.sh 68
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

# Get job ID from command line or use the most recent one
JOB_ID="${1:-}"

# Get AAP token from vault
print_info "Getting AAP token from vault..."
cd "$PROJECT_ROOT"
AAP_TOKEN=$(ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep vault_aap_token | cut -d'"' -f2)

if [ -z "$AAP_TOKEN" ]; then
    print_error "Could not retrieve AAP token from vault"
    exit 1
fi

if [ -z "$JOB_ID" ]; then
    print_info "No job ID provided, finding most recent job..."
    JOB_ID=$(curl -s \
      -H "Authorization: Bearer $AAP_TOKEN" \
      -H "Content-Type: application/json" \
      "$AAP_URL/api/v2/jobs/?page_size=1&order_by=-created" \
      | jq -r '.results[0].id')
    
    if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
        print_error "Could not find any jobs"
        exit 1
    fi
    print_info "Using most recent job: $JOB_ID"
fi

print_header "AAP Job Debug: $JOB_ID"

print_step "Step 1: Get Job Details"
JOB_DATA=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/jobs/$JOB_ID/")

if echo "$JOB_DATA" | jq -e '.id' > /dev/null; then
    print_success "Job found"
    echo "$JOB_DATA" | jq -r '"  • Job ID: \(.id)
  • Name: \(.name)
  • Status: \(.status)
  • Started: \(.started // "Not started")
  • Finished: \(.finished // "Not finished")
  • Elapsed: \(.elapsed // 0) seconds
  • Job Template: \(.job_template)
  • Playbook: \(.playbook)"'
else
    print_error "Job not found or API error"
    echo "$JOB_DATA" | jq '.'
    exit 1
fi

print_step "Step 2: Get Job Events (Last 10)"
JOB_EVENTS=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/jobs/$JOB_ID/job_events/?page_size=10&order_by=-created")

EVENT_COUNT=$(echo "$JOB_EVENTS" | jq '.count')
if [ "$EVENT_COUNT" -gt 0 ]; then
    print_success "Found $EVENT_COUNT job events (showing last 10):"
    echo "$JOB_EVENTS" | jq -r '.results[] | "  • \(.created): \(.event) - \(.task // "N/A") - \(.event_data.res.msg // .stdout // "No message")"' | head -10
else
    print_info "No job events found"
fi

print_step "Step 3: Get Job Output/Stdout"
JOB_STDOUT=$(curl -s \
  -H "Authorization: Bearer $AAP_TOKEN" \
  -H "Content-Type: application/json" \
  "$AAP_URL/api/v2/jobs/$JOB_ID/stdout/?format=txt")

if [ -n "$JOB_STDOUT" ] && [ "$JOB_STDOUT" != "null" ]; then
    print_info "Job output (last 20 lines):"
    echo "$JOB_STDOUT" | tail -20
else
    print_info "No job output available yet"
fi

print_step "Step 4: Check Job Variables/Extra Vars"
EXTRA_VARS=$(echo "$JOB_DATA" | jq -r '.extra_vars // "{}"')
if [ "$EXTRA_VARS" != "{}" ]; then
    print_info "Job extra variables:"
    echo "$EXTRA_VARS" | jq '.'
else
    print_info "No extra variables"
fi

print_step "Step 5: Get Job Template Info"
JOB_TEMPLATE_ID=$(echo "$JOB_DATA" | jq -r '.job_template')
if [ "$JOB_TEMPLATE_ID" != "null" ]; then
    TEMPLATE_INFO=$(curl -s \
      -H "Authorization: Bearer $AAP_TOKEN" \
      -H "Content-Type: application/json" \
      "$AAP_URL/api/v2/job_templates/$JOB_TEMPLATE_ID/")
    
    print_info "Job template details:"
    echo "$TEMPLATE_INFO" | jq -r '"  • Template ID: \(.id)
  • Template Name: \(.name)
  • Description: \(.description)
  • Playbook: \(.playbook)"'
fi

print_header "Job Debug Summary"
JOB_STATUS=$(echo "$JOB_DATA" | jq -r '.status')
JOB_NAME=$(echo "$JOB_DATA" | jq -r '.name')
STARTED=$(echo "$JOB_DATA" | jq -r '.started // "Not started"')
FINISHED=$(echo "$JOB_DATA" | jq -r '.finished // "Not finished"')

echo -e "${CYAN}• Job ID: $JOB_ID${NC}"
echo -e "${CYAN}• Job Name: $JOB_NAME${NC}"
echo -e "${CYAN}• Status: $JOB_STATUS${NC}"
echo -e "${CYAN}• Started: $STARTED${NC}"
echo -e "${CYAN}• Finished: $FINISHED${NC}"
echo -e "${CYAN}• Events: $EVENT_COUNT${NC}"
echo -e "${CYAN}• Job URL: $AAP_URL/#/jobs/playbook/$JOB_ID${NC}"
