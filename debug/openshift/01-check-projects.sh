#!/bin/bash
#
# Debug Script 1: Check OpenShift Projects
# Validates OpenShift connectivity and lists projects
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

print_header "OpenShift Projects Debug"

print_step "Step 1: Check OpenShift Connectivity"
if oc whoami &>/dev/null; then
    CURRENT_USER=$(oc whoami)
    CURRENT_SERVER=$(oc whoami --show-server)
    print_success "Connected to OpenShift as: $CURRENT_USER"
    print_info "Server: $CURRENT_SERVER"
else
    print_error "Not connected to OpenShift cluster"
    print_info "Please run 'oc login' to authenticate"
    exit 1
fi

print_step "Step 2: List All Projects"
ALL_PROJECTS=$(oc get projects --no-headers 2>/dev/null | wc -l)
if [ "$ALL_PROJECTS" -gt 0 ]; then
    print_success "Found $ALL_PROJECTS total projects"
    print_info "All projects:"
    oc get projects --no-headers | awk '{printf "  • %s - Status: %s - Age: %s\n", $1, $2, $3}'
else
    print_error "No projects found or insufficient permissions"
fi

print_step "Step 3: Check ServiceNow-Created Projects"
SERVICENOW_PROJECTS=$(oc get projects --no-headers 2>/dev/null | grep -E "(servicenow|snow)" | wc -l)
if [ "$SERVICENOW_PROJECTS" -gt 0 ]; then
    print_success "Found $SERVICENOW_PROJECTS ServiceNow-related projects:"
    oc get projects --no-headers | grep -E "(servicenow|snow)" | awk '{printf "  • %s - Status: %s - Age: %s\n", $1, $2, $3}'
else
    print_info "No ServiceNow-related projects found"
fi

print_step "Step 4: Check Recent Projects (Last 24 hours)"
print_info "Projects created in the last 24 hours:"
# Get projects and check their creation time
RECENT_COUNT=0
while IFS= read -r project; do
    PROJECT_NAME=$(echo "$project" | awk '{print $1}')
    if [ -n "$PROJECT_NAME" ] && [ "$PROJECT_NAME" != "NAME" ]; then
        CREATION_TIME=$(oc get project "$PROJECT_NAME" -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "")
        if [ -n "$CREATION_TIME" ]; then
            # Convert to epoch time for comparison (simplified check)
            CREATION_DATE=$(date -d "$CREATION_TIME" +%s 2>/dev/null || echo "0")
            YESTERDAY=$(date -d "24 hours ago" +%s)
            
            if [ "$CREATION_DATE" -gt "$YESTERDAY" ]; then
                echo "  • $PROJECT_NAME - Created: $CREATION_TIME"
                ((RECENT_COUNT++))
            fi
        fi
    fi
done < <(oc get projects --no-headers 2>/dev/null)

if [ "$RECENT_COUNT" -eq 0 ]; then
    print_info "No projects created in the last 24 hours"
fi

print_step "Step 5: Check Project Permissions"
CURRENT_PROJECT=$(oc project -q 2>/dev/null || echo "")
if [ -n "$CURRENT_PROJECT" ]; then
    print_info "Current project: $CURRENT_PROJECT"
    
    # Check if user can create projects
    if oc auth can-i create projects &>/dev/null; then
        print_success "User can create projects"
    else
        print_info "User cannot create projects (may need cluster-admin or project creation permissions)"
    fi
    
    # Check if user can list all projects
    if oc auth can-i list projects &>/dev/null; then
        print_success "User can list projects"
    else
        print_info "User has limited project visibility"
    fi
else
    print_info "No current project set"
fi

print_step "Step 6: Check Cluster Info"
CLUSTER_VERSION=$(oc version --short 2>/dev/null | grep "Server Version" | cut -d' ' -f3 || echo "Unknown")
print_info "OpenShift version: $CLUSTER_VERSION"

# Check cluster nodes (if accessible)
NODE_COUNT=$(oc get nodes --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$NODE_COUNT" -gt 0 ]; then
    print_info "Cluster has $NODE_COUNT nodes"
else
    print_info "Node information not accessible"
fi

print_header "OpenShift Debug Summary"
echo -e "${CYAN}• Connected User: $CURRENT_USER${NC}"
echo -e "${CYAN}• Server: $CURRENT_SERVER${NC}"
echo -e "${CYAN}• Total Projects: $ALL_PROJECTS${NC}"
echo -e "${CYAN}• ServiceNow Projects: $SERVICENOW_PROJECTS${NC}"
echo -e "${CYAN}• Recent Projects: $RECENT_COUNT${NC}"
echo -e "${CYAN}• OpenShift Version: $CLUSTER_VERSION${NC}"
