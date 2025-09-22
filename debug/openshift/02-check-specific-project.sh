#!/bin/bash
#
# Debug Script 2: Check Specific OpenShift Project
# Usage: ./02-check-specific-project.sh [PROJECT_NAME]
# Example: ./02-check-specific-project.sh servicenow-real-1758225510
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

# Get project name from command line
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
    print_error "Usage: $0 <PROJECT_NAME>"
    print_info "Example: $0 servicenow-real-1758225510"
    exit 1
fi

print_header "OpenShift Project Debug: $PROJECT_NAME"

print_step "Step 1: Check if Project Exists"
if oc get project "$PROJECT_NAME" &>/dev/null; then
    print_success "Project '$PROJECT_NAME' exists"
    
    # Get project details
    CREATION_TIME=$(oc get project "$PROJECT_NAME" -o jsonpath='{.metadata.creationTimestamp}')
    PROJECT_UID=$(oc get project "$PROJECT_NAME" -o jsonpath='{.metadata.uid}')
    PROJECT_STATUS=$(oc get project "$PROJECT_NAME" -o jsonpath='{.status.phase}')
    
    print_info "Project details:"
    echo "  • Name: $PROJECT_NAME"
    echo "  • UID: $PROJECT_UID"
    echo "  • Status: $PROJECT_STATUS"
    echo "  • Created: $CREATION_TIME"
else
    print_error "Project '$PROJECT_NAME' does not exist"
    
    print_info "Similar projects found:"
    oc get projects --no-headers | grep -i servicenow | head -5 | awk '{printf "  • %s\n", $1}' || echo "  • No similar projects found"
    exit 1
fi

print_step "Step 2: Check Project Resources"
# Switch to the project
oc project "$PROJECT_NAME" &>/dev/null

# Check pods
POD_COUNT=$(oc get pods --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" -gt 0 ]; then
    print_success "Found $POD_COUNT pods:"
    oc get pods --no-headers | awk '{printf "  • %s - Status: %s - Age: %s\n", $1, $3, $5}'
else
    print_info "No pods found in project"
fi

# Check services
SERVICE_COUNT=$(oc get services --no-headers 2>/dev/null | wc -l)
if [ "$SERVICE_COUNT" -gt 0 ]; then
    print_success "Found $SERVICE_COUNT services:"
    oc get services --no-headers | awk '{printf "  • %s - Type: %s - Cluster-IP: %s\n", $1, $2, $3}'
else
    print_info "No services found in project"
fi

# Check deployments
DEPLOYMENT_COUNT=$(oc get deployments --no-headers 2>/dev/null | wc -l)
if [ "$DEPLOYMENT_COUNT" -gt 0 ]; then
    print_success "Found $DEPLOYMENT_COUNT deployments:"
    oc get deployments --no-headers | awk '{printf "  • %s - Ready: %s - Available: %s - Age: %s\n", $1, $2, $4, $5}'
else
    print_info "No deployments found in project"
fi

print_step "Step 3: Check Project Labels and Annotations"
LABELS=$(oc get project "$PROJECT_NAME" -o jsonpath='{.metadata.labels}' 2>/dev/null)
ANNOTATIONS=$(oc get project "$PROJECT_NAME" -o jsonpath='{.metadata.annotations}' 2>/dev/null)

if [ "$LABELS" != "{}" ] && [ -n "$LABELS" ]; then
    print_info "Project labels:"
    echo "$LABELS" | jq -r 'to_entries[] | "  • \(.key): \(.value)"' 2>/dev/null || echo "  • $LABELS"
else
    print_info "No custom labels found"
fi

if [ "$ANNOTATIONS" != "{}" ] && [ -n "$ANNOTATIONS" ]; then
    print_info "Project annotations:"
    echo "$ANNOTATIONS" | jq -r 'to_entries[] | "  • \(.key): \(.value)"' 2>/dev/null || echo "  • $ANNOTATIONS"
else
    print_info "No custom annotations found"
fi

print_step "Step 4: Check Project Events"
EVENTS=$(oc get events --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -5)
if [ -n "$EVENTS" ]; then
    print_info "Recent events (last 5):"
    echo "$EVENTS" | awk '{printf "  • %s %s: %s\n", $1, $4, $6}'
else
    print_info "No recent events found"
fi

print_step "Step 5: Check Resource Quotas and Limits"
QUOTAS=$(oc get resourcequotas --no-headers 2>/dev/null | wc -l)
if [ "$QUOTAS" -gt 0 ]; then
    print_success "Found $QUOTAS resource quotas:"
    oc get resourcequotas --no-headers | awk '{printf "  • %s - Age: %s\n", $1, $2}'
else
    print_info "No resource quotas found"
fi

LIMIT_RANGES=$(oc get limitranges --no-headers 2>/dev/null | wc -l)
if [ "$LIMIT_RANGES" -gt 0 ]; then
    print_success "Found $LIMIT_RANGES limit ranges:"
    oc get limitranges --no-headers | awk '{printf "  • %s - Age: %s\n", $1, $2}'
else
    print_info "No limit ranges found"
fi

print_step "Step 6: Check Project Network Policies"
NETWORK_POLICIES=$(oc get networkpolicies --no-headers 2>/dev/null | wc -l)
if [ "$NETWORK_POLICIES" -gt 0 ]; then
    print_success "Found $NETWORK_POLICIES network policies:"
    oc get networkpolicies --no-headers | awk '{printf "  • %s - Age: %s\n", $1, $2}'
else
    print_info "No network policies found"
fi

print_header "Project Debug Summary"
echo -e "${CYAN}• Project Name: $PROJECT_NAME${NC}"
echo -e "${CYAN}• Project Status: $PROJECT_STATUS${NC}"
echo -e "${CYAN}• Created: $CREATION_TIME${NC}"
echo -e "${CYAN}• Pods: $POD_COUNT${NC}"
echo -e "${CYAN}• Services: $SERVICE_COUNT${NC}"
echo -e "${CYAN}• Deployments: $DEPLOYMENT_COUNT${NC}"
echo -e "${CYAN}• Resource Quotas: $QUOTAS${NC}"
echo -e "${CYAN}• Limit Ranges: $LIMIT_RANGES${NC}"
