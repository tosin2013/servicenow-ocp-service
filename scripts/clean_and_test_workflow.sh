#!/bin/bash
#
# 🧹🧪 Clean and Test Workflow
# Comprehensive ServiceNow cleanup and idempotent testing
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

# Function to run playbooks
run_playbook() {
    local playbook="$1"
    local description="$2"
    local extra_args="${3:-}"

    print_info "Running: $description"
    print_info "Playbook: ../ansible/$playbook"

    cd "$PROJECT_ROOT"

    local cmd="$ANSIBLE_CMD_BASE ../ansible/$playbook $VAULT_ARGS $extra_args"
    print_info "Command: $cmd"

    if eval "$cmd"; then
        print_success "$description completed successfully"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Step 1: Diagnostic Check
run_diagnostic() {
    print_step "1" "Running Diagnostic Check"
    print_info "Checking current state of ServiceNow instance..."
    
    if run_playbook "diagnose_servicenow_requests.yml" "ServiceNow Diagnostic"; then
        print_success "Diagnostic completed - check output for current state"
        return 0
    else
        print_warning "Diagnostic had issues but continuing..."
        return 0
    fi
}

# Step 2: Cleanup Test Data
run_cleanup() {
    print_step "2" "Cleaning Up Test Data"
    print_warning "This will delete test data from ServiceNow"
    
    echo -e "${YELLOW}Continue with cleanup? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if run_playbook "cleanup_servicenow_test_data.yml" "ServiceNow Cleanup"; then
            print_success "Cleanup completed successfully"
            return 0
        else
            print_error "Cleanup failed"
            return 1
        fi
    else
        print_info "Skipping cleanup"
        return 0
    fi
}

# Step 3: Run Idempotent Test
run_idempotent_test() {
    print_step "3" "Running Idempotent End-to-End Test"
    print_info "This test updates existing items instead of creating duplicates"
    
    if run_playbook "idempotent_end_to_end_test.yml" "Idempotent E2E Test"; then
        print_success "Idempotent test completed successfully"
        return 0
    else
        print_error "Idempotent test failed"
        return 1
    fi
}

# Step 4: Validate Business Rules
validate_business_rules() {
    print_step "4" "Validating Business Rules"
    print_info "Checking if Business Rules are properly configured"
    
    if run_playbook "validate_business_rules.yml" "Business Rules Validation"; then
        print_success "Business Rules validation completed"
        return 0
    else
        print_warning "Business Rules validation had issues"
        return 0
    fi
}

# Step 5: Final Status Check
final_status_check() {
    print_step "5" "Final Status Check"
    print_info "Checking final state after testing"
    
    # Check ServiceNow dashboard URLs
    echo -e "\n${CYAN}🔗 ServiceNow Dashboard URLs:${NC}"
    echo -e "• Requests: https://dev295398.service-now.com/nav_to.do?uri=sc_request_list.do"
    echo -e "• Requested Items: https://dev295398.service-now.com/nav_to.do?uri=sc_req_item_list.do"
    echo -e "• Business Rules: https://dev295398.service-now.com/nav_to.do?uri=sys_script_list.do"
    
    # Check AAP
    echo -e "\n${CYAN}🚀 AAP Dashboard:${NC}"
    echo -e "• Jobs: https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/#/jobs"
    
    # Check OpenShift
    echo -e "\n${CYAN}🏗️ OpenShift Projects:${NC}"
    if command -v oc >/dev/null 2>&1; then
        print_info "Recent OpenShift projects:"
        oc get projects --no-headers | grep -E "e2e|test" | head -5 || echo "No test projects found"
    else
        print_warning "oc command not available"
    fi
}

# Main workflow
main() {
    local mode="${1:-full}"
    
    clear
    print_header "🧹🧪 Clean and Test Workflow"
    
    echo -e "\n${BOLD}ServiceNow-OpenShift Integration Testing${NC}"
    echo -e "Comprehensive cleanup and idempotent testing workflow"
    echo ""
    echo -e "${CYAN}Mode: $mode${NC}"
    echo -e "${CYAN}Project Root: $PROJECT_ROOT${NC}"
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
    
    print_success "Prerequisites verified"
    echo ""
    
    case "$mode" in
        "diagnostic")
            run_diagnostic
            ;;
        "cleanup")
            run_cleanup
            ;;
        "test")
            run_idempotent_test
            ;;
        "validate")
            validate_business_rules
            ;;
        "full")
            echo -e "${YELLOW}Running full workflow...${NC}"
            echo -e "${YELLOW}Press Enter to continue or Ctrl+C to exit...${NC}"
            read -r
            
            local success=true
            
            run_diagnostic || success=false
            
            if [ "$success" = "true" ]; then
                run_cleanup || success=false
            fi
            
            if [ "$success" = "true" ]; then
                run_idempotent_test || success=false
            fi
            
            if [ "$success" = "true" ]; then
                validate_business_rules || success=false
            fi
            
            final_status_check
            
            if [ "$success" = "true" ]; then
                print_success "🎉 Full workflow completed successfully!"
            else
                print_error "❌ Workflow completed with issues"
            fi
            ;;
        *)
            echo "Usage: $0 [diagnostic|cleanup|test|validate|full]"
            echo ""
            echo "Modes:"
            echo "  diagnostic : Check current ServiceNow state"
            echo "  cleanup    : Clean up test data"
            echo "  test       : Run idempotent end-to-end test"
            echo "  validate   : Validate Business Rules"
            echo "  full       : Run complete workflow (default)"
            exit 1
            ;;
    esac
}

# Show usage if help requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "🧹🧪 Clean and Test Workflow"
    echo ""
    echo "This script provides a comprehensive workflow for:"
    echo "1. Diagnosing ServiceNow state"
    echo "2. Cleaning up test data"
    echo "3. Running idempotent tests"
    echo "4. Validating Business Rules"
    echo ""
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  diagnostic : Check current ServiceNow state"
    echo "  cleanup    : Clean up test data"
    echo "  test       : Run idempotent end-to-end test"
    echo "  validate   : Validate Business Rules"
    echo "  full       : Run complete workflow (default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run full workflow"
    echo "  $0 diagnostic         # Just check current state"
    echo "  $0 cleanup            # Just clean up test data"
    echo "  $0 test               # Just run idempotent test"
    echo ""
    exit 0
fi

main "$@"
