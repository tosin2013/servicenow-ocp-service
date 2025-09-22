#!/bin/bash
#
# Master Debug Script: Run Full Integration Debug
# This script runs all debug checks in sequence
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..80})${NC}"
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

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/servicenow/*.sh
chmod +x "$SCRIPT_DIR"/aap/*.sh
chmod +x "$SCRIPT_DIR"/openshift/*.sh

print_header "🚀 ServiceNow-OpenShift Integration Full Debug Suite"
echo -e "${CYAN}Starting comprehensive integration debug...${NC}"

# Track results
SERVICENOW_OK=false
AAP_OK=false
OPENSHIFT_OK=false

print_header "1️⃣  ServiceNow Integration Debug"

print_step "Running ServiceNow Catalog Items Check"
if "$SCRIPT_DIR/servicenow/01-check-catalog-items.sh"; then
    print_success "ServiceNow catalog check completed"
    SERVICENOW_OK=true
else
    print_error "ServiceNow catalog check failed"
fi

print_step "Running ServiceNow Request Check"
if "$SCRIPT_DIR/servicenow/02-check-specific-request.sh"; then
    print_success "ServiceNow request check completed"
else
    print_error "ServiceNow request check failed"
fi

print_header "2️⃣  AAP Integration Debug"

print_step "Running AAP Connectivity Check"
if "$SCRIPT_DIR/aap/01-check-aap-connectivity.sh"; then
    print_success "AAP connectivity check completed"
    AAP_OK=true
else
    print_error "AAP connectivity check failed"
fi

print_step "Running AAP Job Check"
if "$SCRIPT_DIR/aap/02-check-specific-job.sh"; then
    print_success "AAP job check completed"
else
    print_error "AAP job check failed"
fi

print_header "3️⃣  OpenShift Integration Debug"

print_step "Running OpenShift Projects Check"
if "$SCRIPT_DIR/openshift/01-check-projects.sh"; then
    print_success "OpenShift projects check completed"
    OPENSHIFT_OK=true
else
    print_error "OpenShift projects check failed"
fi

# Check for specific ServiceNow projects
print_step "Checking for ServiceNow-created projects"
SERVICENOW_PROJECTS=$(oc get projects --no-headers 2>/dev/null | grep -E "(servicenow|snow)" || echo "")
if [ -n "$SERVICENOW_PROJECTS" ]; then
    print_info "Found ServiceNow projects, checking details..."
    while IFS= read -r project_line; do
        PROJECT_NAME=$(echo "$project_line" | awk '{print $1}')
        if [ -n "$PROJECT_NAME" ]; then
            print_info "Checking project: $PROJECT_NAME"
            "$SCRIPT_DIR/openshift/02-check-specific-project.sh" "$PROJECT_NAME" || true
        fi
    done <<< "$SERVICENOW_PROJECTS"
else
    print_info "No ServiceNow projects found to check"
fi

print_header "🎯 Integration Debug Summary"

echo -e "\n${BOLD}Component Status:${NC}"
if [ "$SERVICENOW_OK" = true ]; then
    echo -e "${GREEN}✅ ServiceNow: Connected and functional${NC}"
else
    echo -e "${RED}❌ ServiceNow: Issues detected${NC}"
fi

if [ "$AAP_OK" = true ]; then
    echo -e "${GREEN}✅ AAP: Connected and functional${NC}"
else
    echo -e "${RED}❌ AAP: Issues detected${NC}"
fi

if [ "$OPENSHIFT_OK" = true ]; then
    echo -e "${GREEN}✅ OpenShift: Connected and functional${NC}"
else
    echo -e "${RED}❌ OpenShift: Issues detected${NC}"
fi

echo -e "\n${BOLD}Integration Flow Status:${NC}"
if [ "$SERVICENOW_OK" = true ] && [ "$AAP_OK" = true ] && [ "$OPENSHIFT_OK" = true ]; then
    echo -e "${GREEN}✅ All components are functional${NC}"
    echo -e "${CYAN}🔄 Integration flow should work end-to-end${NC}"
else
    echo -e "${YELLOW}⚠️  Some components have issues${NC}"
    echo -e "${CYAN}🔧 Check individual component logs above${NC}"
fi

echo -e "\n${BOLD}Next Steps:${NC}"
echo -e "${CYAN}• Review any error messages above${NC}"
echo -e "${CYAN}• Check specific component logs for detailed troubleshooting${NC}"
echo -e "${CYAN}• Run individual debug scripts for focused testing${NC}"
echo -e "${CYAN}• Use: ./debug/servicenow/01-check-catalog-items.sh${NC}"
echo -e "${CYAN}• Use: ./debug/aap/02-check-specific-job.sh [JOB_ID]${NC}"
echo -e "${CYAN}• Use: ./debug/openshift/02-check-specific-project.sh [PROJECT_NAME]${NC}"

print_header "Debug Complete"
