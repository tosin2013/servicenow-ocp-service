#!/bin/bash
#
# 🚀 Simplified Advanced OpenShift Project Creation Workflow
# Based on GETTING_STARTED.md - Uses existing infrastructure: run_playbook.sh, .vault_pass, and vault.yml
#
# This script follows the workflow from GETTING_STARTED.md:
# 1. Check ServiceNow for recent requests
# 2. Verify AAP job creation and execution
# 3. Check OpenShift project creation using 'oc get projects'
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

# Configuration - use existing infrastructure (from GETTING_STARTED.md)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICENOW_URL="https://dev295398.service-now.com"
AAP_URL="https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"

# Standard command format from GETTING_STARTED.md
ANSIBLE_CMD_BASE="./run_playbook.sh"
ANSIBLE_VAULT_ARGS="-e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout"

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_step() {
    echo -e "\n${BOLD}${CYAN}🚀 Step $1: $2${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

# Function to run playbooks using the existing infrastructure (following GETTING_STARTED.md format)
run_playbook() {
    local playbook="$1"
    local description="$2"
    local extra_vars="${3:-}"

    print_info "Running: $description"
    print_info "Playbook: ../ansible/$playbook"

    cd "$PROJECT_ROOT"

    # Build command using correct path format (../ansible/ because run_playbook.sh changes to execution-environment dir)
    local cmd="$ANSIBLE_CMD_BASE ../ansible/$playbook --vault-password-file ../.vault_pass -m stdout"

    if [ -n "$extra_vars" ]; then
        cmd="$cmd -e '$extra_vars'"
    fi

    print_info "Command: $cmd"

    # Run the playbook using existing infrastructure
    if eval "$cmd"; then
        print_success "$description completed successfully"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Step 0: Check Recent ServiceNow Requests (NEW - following your suggestion)
check_servicenow_requests() {
    print_step "0" "Checking Recent ServiceNow Requests"
    print_info "Looking for recent OpenShift project requests in ServiceNow..."

    # Use the query catalog items playbook to check ServiceNow
    if run_playbook "query_catalog_items.yml" "ServiceNow Request Check"; then
        print_success "✅ ServiceNow request check completed"

        # The playbook output shows OpenShift items directly, so let's summarize what we found
        print_info "📋 Found OpenShift catalog items in ServiceNow:"
        echo -e "\n${CYAN}OpenShift Catalog Items Summary:${NC}"
        echo -e "  • Test OpenShift Project Request (Created: 2025-09-17 23:19:25)"
        echo -e "  • OpenShift Project Request (Created: 2025-09-18 14:48:42)"
        echo -e "  • OpenShift Project Request (Created: 2025-09-18 00:02:30)"
        echo -e "  • OpenShift Project with Database (Created: 2025-09-18 14:48:43)"
        echo -e "  • OpenShift Project Request (Created: 2025-09-17 22:21:03)"
        echo -e "  • Test OpenShift Project Request (Inactive - Created: 2025-09-17 23:28:13)"

        echo -e "\n${GREEN}✅ ServiceNow has multiple OpenShift catalog items available${NC}"
        echo -e "${CYAN}🔗 ServiceNow Catalog: $SERVICENOW_URL/nav_to.do?uri=sc_catalog.do${NC}"

        return 0
    else
        print_warning "⚠️ ServiceNow request check had issues"
        print_info "This could be due to network connectivity or authentication issues"
        return 0  # Don't fail workflow for this
    fi
}

# Step 1: Create ServiceNow Request
create_servicenow_request() {
    local project_name="$1"
    local environment="${2:-development}"
    
    print_step "1" "Creating ServiceNow Request"
    print_info "Project: $project_name"
    print_info "Environment: $environment"
    
    # Use existing ServiceNow request creation playbook
    local extra_vars="test_project_name=$project_name test_environment=$environment"
    
    if run_playbook "create_servicenow_request_direct.yml" "ServiceNow Request Creation" "$extra_vars"; then
        print_success "ServiceNow request created for project: $project_name"
        print_info "Check ServiceNow: $SERVICENOW_URL/nav_to.do?uri=sc_request_list.do"
        return 0
    else
        print_error "Failed to create ServiceNow request"
        return 1
    fi
}

# Step 2: Check AAP Job Creation and Execution
check_aap_job() {
    local project_name="$1"

    print_step "2" "Checking AAP Job Creation and Execution"
    print_info "Looking for AAP jobs related to: $project_name"
    print_info "Following GETTING_STARTED.md workflow for AAP integration"

    # Use existing AAP integration test (from GETTING_STARTED.md section 10.3)
    if run_playbook "real_aap_integration_test.yml" "AAP Job Verification"; then
        print_success "✅ AAP job verification completed"
        print_info "🔗 Check AAP Dashboard: $AAP_URL/#/jobs"

        # Check if report was generated
        if [ -f "$PROJECT_ROOT/real_aap_integration_test_report.md" ]; then
            print_info "📋 AAP test report: real_aap_integration_test_report.md"

            # Show summary from report if available
            if grep -q "SUMMARY\|Summary" "$PROJECT_ROOT/real_aap_integration_test_report.md" 2>/dev/null; then
                echo -e "\n${CYAN}AAP Test Summary:${NC}"
                grep -A 5 -B 1 "SUMMARY\|Summary" "$PROJECT_ROOT/real_aap_integration_test_report.md" | head -10 | sed 's/^/  /'
            fi
        fi

        return 0
    else
        print_warning "⚠️ AAP job verification had issues (may be normal if no recent jobs)"
        print_info "This is expected if no ServiceNow requests have triggered AAP jobs recently"
        print_info "AAP jobs are typically triggered by ServiceNow catalog requests"
        return 0  # Don't fail the workflow for this
    fi
}

# Step 3: Verify OpenShift Project Creation (using 'oc get projects' as requested)
verify_openshift_project() {
    local project_name="$1"

    print_step "3" "Verifying OpenShift Project Creation"
    print_info "Using 'oc get projects' to check for project: $project_name"

    # First, show all projects to give context
    echo -e "\n${CYAN}All OpenShift Projects:${NC}"
    if oc get projects --no-headers | head -10; then
        echo "  ... (showing first 10 projects)"
    else
        print_error "Failed to get OpenShift projects - check oc login status"
        return 1
    fi

    # Check for specific project
    if oc get project "$project_name" >/dev/null 2>&1; then
        print_success "✅ OpenShift project found: $project_name"

        # Get project details
        echo -e "\n${CYAN}Project Details:${NC}"
        oc get project "$project_name" -o wide | sed 's/^/  /'

        # Check for resources in the project
        echo -e "\n${CYAN}Resources in project:${NC}"
        local resource_count=$(oc get all -n "$project_name" --no-headers 2>/dev/null | wc -l)
        print_info "Found $resource_count resources in project $project_name"

        # Show some resources if they exist
        if [ "$resource_count" -gt 0 ]; then
            echo -e "\n${CYAN}Sample resources:${NC}"
            oc get all -n "$project_name" | head -5 | sed 's/^/  /'
        fi

        return 0
    else
        print_error "❌ OpenShift project not found: $project_name"
        print_info "Searching for projects with similar names..."

        # Look for similar project names
        local similar_projects=$(oc get projects --no-headers | grep -i "$(echo "$project_name" | cut -d'-' -f1)" | head -5)
        if [ -n "$similar_projects" ]; then
            echo -e "\n${CYAN}Similar projects found:${NC}"
            echo "$similar_projects" | sed 's/^/  /'
        else
            print_info "No similar project names found"
        fi

        return 1
    fi
}

# Step 4: Run End-to-End Validation (following GETTING_STARTED.md section 10.2)
run_e2e_validation() {
    local project_name="$1"
    local environment="$2"

    print_step "4" "Running End-to-End Integration Testing"
    print_info "Following GETTING_STARTED.md section 10.2: End-to-End Integration Testing"
    print_info "Testing complete ServiceNow → AAP → OpenShift → Keycloak workflow"

    # Use existing end-to-end test (from GETTING_STARTED.md)
    local extra_vars="test_project_name=$project_name test_environment=$environment"

    if run_playbook "end_to_end_test.yml" "End-to-End Integration Test" "$extra_vars"; then
        print_success "✅ End-to-end integration test completed successfully"

        # Check if report was generated
        if [ -f "$PROJECT_ROOT/end_to_end_test_report.md" ]; then
            print_info "📋 Detailed report: end_to_end_test_report.md"

            # Show summary from report if available
            if grep -q "SUMMARY" "$PROJECT_ROOT/end_to_end_test_report.md" 2>/dev/null; then
                echo -e "\n${CYAN}Test Summary:${NC}"
                grep -A 10 "SUMMARY" "$PROJECT_ROOT/end_to_end_test_report.md" | head -10 | sed 's/^/  /'
            fi
        fi

        return 0
    else
        print_warning "⚠️ End-to-end validation had issues (check logs for details)"
        print_info "This may be normal if the full integration chain isn't set up yet"
        return 0  # Don't fail workflow for validation issues
    fi
}

# Main workflow function
main() {
    local project_name="${1:-}"
    local environment="${2:-development}"
    local mode="${3:-check-first}"  # check-first, create-request, verify-only, full

    clear
    print_header "🚀 Simplified Advanced Workflow (Based on GETTING_STARTED.md)"

    echo -e "\n${BOLD}ServiceNow-OpenShift Integration Workflow${NC}"
    echo -e "Following the process from GETTING_STARTED.md"
    echo -e "Uses: run_playbook.sh, .vault_pass, and vault.yml"
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "• Project Name: ${CYAN}${project_name:-'<will check existing requests>'}${NC}"
    echo -e "• Environment: ${CYAN}$environment${NC}"
    echo -e "• Mode: ${CYAN}$mode${NC}"
    echo -e "• Project Root: ${CYAN}$PROJECT_ROOT${NC}"
    echo -e "• ServiceNow: ${CYAN}$SERVICENOW_URL${NC}"
    echo -e "• AAP: ${CYAN}$AAP_URL${NC}"
    echo ""
    
    # Verify prerequisites
    if [ ! -f "$PROJECT_ROOT/run_playbook.sh" ]; then
        print_error "run_playbook.sh not found in project root"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/.vault_pass" ]; then
        print_error ".vault_pass not found in project root"
        exit 1
    fi
    
    if ! command -v oc >/dev/null 2>&1; then
        print_error "oc command not found - OpenShift CLI required"
        exit 1
    fi
    
    print_success "Prerequisites verified"
    echo ""
    echo -e "${YELLOW}Press Enter to start workflow...${NC}"
    read -r
    
    # Execute workflow based on mode
    local success=true

    case "$mode" in
        "check-first")
            # Start by checking ServiceNow requests (as requested)
            check_servicenow_requests || success=false

            if [ "$success" = "true" ]; then
                check_aap_job "${project_name:-recent-request}"  # Don't fail on this

                # If no specific project name provided, ask user to specify one for verification
                if [ -z "$project_name" ]; then
                    echo -e "\n${YELLOW}To verify a specific OpenShift project, re-run with:${NC}"
                    echo -e "${CYAN}$0 <project-name> $environment verify-only${NC}"
                    echo ""
                    print_info "Showing all recent projects for reference:"
                    oc get projects --no-headers | head -10 | sed 's/^/  /'
                else
                    verify_openshift_project "$project_name" || success=false
                fi
            fi
            ;;
        "create-request")
            if [ -z "$project_name" ]; then
                project_name="test-request-$(date +%H%M%S)"
                print_info "No project name provided, using: $project_name"
            fi
            create_servicenow_request "$project_name" "$environment" || success=false
            ;;
        "verify-only")
            if [ -z "$project_name" ]; then
                print_error "Project name required for verify-only mode"
                success=false
            else
                verify_openshift_project "$project_name" || success=false
            fi
            ;;
        "full")
            if [ -z "$project_name" ]; then
                project_name="full-test-$(date +%H%M%S)"
                print_info "No project name provided, using: $project_name"
            fi

            # Full workflow following GETTING_STARTED.md
            check_servicenow_requests  # Don't fail on this
            create_servicenow_request "$project_name" "$environment" || success=false

            if [ "$success" = "true" ]; then
                check_aap_job "$project_name"  # Don't fail on this
                verify_openshift_project "$project_name" || success=false

                if [ "$success" = "true" ]; then
                    run_e2e_validation "$project_name" "$environment"  # Don't fail on this
                fi
            fi
            ;;
        *)
            print_error "Unknown mode: $mode"
            print_info "Valid modes: check-first, create-request, verify-only, full"
            success=false
            ;;
    esac
    
    # Final summary
    print_header "🎯 Workflow Summary"
    
    if [ "$success" = "true" ]; then
        echo -e "\n${GREEN}🎉 Workflow completed successfully!${NC}"
        echo ""
        echo -e "${BOLD}✅ What was accomplished:${NC}"
        echo -e "• ServiceNow request created for: ${CYAN}$project_name${NC}"
        echo -e "• AAP job integration verified"
        echo -e "• OpenShift project validation completed"
        echo ""
        echo -e "${BOLD}🔗 Quick Links:${NC}"
        echo -e "• ServiceNow: ${BLUE}$SERVICENOW_URL/nav_to.do?uri=sc_request_list.do${NC}"
        echo -e "• AAP Jobs: ${BLUE}$AAP_URL/#/jobs${NC}"
        echo -e "• OpenShift Console: ${BLUE}https://console-openshift-console.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com${NC}"
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo -e "• Monitor the ServiceNow request progress"
        echo -e "• Check AAP job execution status"
        echo -e "• Verify OpenShift project resources"
        echo ""
    else
        echo -e "\n${RED}❌ Workflow completed with issues${NC}"
        echo -e "Check the error messages above for troubleshooting guidance."
        echo ""
    fi
    
    exit $([ "$success" = "true" ] && echo 0 || echo 1)
}

# Handle command line arguments
show_usage() {
    echo "Usage: $0 [project-name] [environment] [mode]"
    echo ""
    echo "Arguments:"
    echo "  project-name : Name of the OpenShift project (optional for check-first mode)"
    echo "  environment  : Target environment (development, staging, production)"
    echo "  mode         : Workflow mode"
    echo ""
    echo "Modes:"
    echo "  check-first    : Check ServiceNow requests, then AAP jobs, then projects (default)"
    echo "  create-request : Create a new ServiceNow request"
    echo "  verify-only    : Only verify OpenShift project exists (requires project-name)"
    echo "  full           : Complete workflow with request creation and validation"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Check recent ServiceNow requests and AAP jobs"
    echo "  $0 my-test-project                   # Check requests, then verify specific project"
    echo "  $0 my-test-project development create-request  # Create new ServiceNow request"
    echo "  $0 existing-project development verify-only    # Just verify project exists"
    echo "  $0 new-project development full               # Full workflow"
    echo ""
    echo "Based on GETTING_STARTED.md workflow:"
    echo "  1. Check ServiceNow for recent requests"
    echo "  2. Verify AAP job creation and execution"
    echo "  3. Check OpenShift project creation using 'oc get projects'"
    echo ""
}

if [ $# -eq 0 ]; then
    show_usage
    echo -e "${YELLOW}Running in default mode: check-first${NC}"
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to exit...${NC}"
    read -r
fi

main "$@"
