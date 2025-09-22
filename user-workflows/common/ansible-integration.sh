#!/bin/bash
#
# 🔧 Common Ansible Integration Functions
# Shared utilities for calling Ansible playbooks from workflow scripts
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
ANSIBLE_DIR="../ansible"
ANSIBLE_LOG_DIR="./logs"
ANSIBLE_TIMEOUT=600  # 10 minutes default timeout

# Ensure log directory exists
mkdir -p "$ANSIBLE_LOG_DIR"

print_ansible_info() {
    echo -e "${BLUE}🔧 ANSIBLE:${NC} $1"
}

print_ansible_success() {
    echo -e "${GREEN}✅ ANSIBLE:${NC} $1"
}

print_ansible_error() {
    echo -e "${RED}❌ ANSIBLE:${NC} $1"
}

print_ansible_warning() {
    echo -e "${YELLOW}⚠️  ANSIBLE:${NC} $1"
}

# Function to run Ansible playbooks with proper logging and error handling
run_ansible_playbook() {
    local playbook="$1"
    local description="$2"
    local extra_vars="${3:-}"
    local log_file="$ANSIBLE_LOG_DIR/$(basename "$playbook" .yml)-$(date +%Y%m%d-%H%M%S).log"
    
    print_ansible_info "Running: $description"
    print_ansible_info "Playbook: $playbook"
    print_ansible_info "Log file: $log_file"
    
    if [ ! -f "$ANSIBLE_DIR/$playbook" ]; then
        print_ansible_error "Playbook not found: $ANSIBLE_DIR/$playbook"
        return 1
    fi
    
    # Build ansible-playbook command
    local cmd="ansible-playbook"
    local args=("-i" "localhost," "$ANSIBLE_DIR/$playbook")
    
    if [ -n "$extra_vars" ]; then
        args+=("--extra-vars" "$extra_vars")
    fi
    
    # Add common arguments
    args+=("--timeout" "$ANSIBLE_TIMEOUT")
    args+=("-v")  # Verbose output
    
    print_ansible_info "Command: $cmd ${args[*]}"
    
    # Run the playbook and capture output
    if timeout "$ANSIBLE_TIMEOUT" "$cmd" "${args[@]}" > "$log_file" 2>&1; then
        print_ansible_success "$description completed successfully"
        
        # Show last few lines of output for immediate feedback
        echo -e "${CYAN}Last 5 lines of output:${NC}"
        tail -5 "$log_file" | sed 's/^/  /'
        
        return 0
    else
        local exit_code=$?
        print_ansible_error "$description failed (exit code: $exit_code)"
        
        # Show error details
        echo -e "${RED}Error details (last 10 lines):${NC}"
        tail -10 "$log_file" | sed 's/^/  /'
        
        return $exit_code
    fi
}

# Function to create ServiceNow request using Ansible
create_servicenow_request_ansible() {
    local project_name="$1"
    local environment="${2:-development}"
    local display_name="${3:-$project_name}"
    local justification="${4:-Automated OpenShift project creation via workflow}"
    
    local extra_vars="project_name=$project_name environment=$environment display_name='$display_name' justification='$justification'"
    
    print_ansible_info "Creating ServiceNow request via Ansible..."
    
    if run_ansible_playbook "create_servicenow_request_direct.yml" "ServiceNow Request Creation" "$extra_vars"; then
        # Extract request number from log file
        local log_file=$(ls -t "$ANSIBLE_LOG_DIR"/create_servicenow_request_direct-*.log | head -1)
        local req_number=$(grep -o "REQ[0-9]\{7\}" "$log_file" | head -1)
        
        if [ -n "$req_number" ]; then
            print_ansible_success "ServiceNow request created: $req_number"
            echo "$req_number"
            return 0
        else
            print_ansible_warning "Request created but number not found in logs"
            echo "REQ_UNKNOWN"
            return 0
        fi
    else
        print_ansible_error "Failed to create ServiceNow request"
        return 1
    fi
}

# Function to run end-to-end test using Ansible
run_end_to_end_test_ansible() {
    local project_name="$1"
    local environment="${2:-development}"
    
    local extra_vars="test_project_name=$project_name test_environment=$environment"
    
    print_ansible_info "Running end-to-end test via Ansible..."
    
    if run_ansible_playbook "end_to_end_test.yml" "End-to-End Integration Test" "$extra_vars"; then
        print_ansible_success "End-to-end test completed successfully"
        
        # Check if report was generated
        if [ -f "./end_to_end_test_report.md" ]; then
            print_ansible_info "Test report generated: ./end_to_end_test_report.md"
        fi
        
        return 0
    else
        print_ansible_error "End-to-end test failed"
        return 1
    fi
}

# Function to validate ServiceNow integration using Ansible
validate_servicenow_integration_ansible() {
    print_ansible_info "Validating ServiceNow integration via Ansible..."
    
    if run_ansible_playbook "debug_servicenow_api.yml" "ServiceNow API Validation"; then
        print_ansible_success "ServiceNow integration validation completed"
        return 0
    else
        print_ansible_error "ServiceNow integration validation failed"
        return 1
    fi
}

# Function to check OpenShift project creation using Ansible
verify_openshift_project_ansible() {
    local project_name="$1"
    
    local extra_vars="project_name=$project_name"
    
    print_ansible_info "Verifying OpenShift project via Ansible..."
    
    if run_ansible_playbook "servicenow_project_creation.yml" "OpenShift Project Verification" "$extra_vars"; then
        print_ansible_success "OpenShift project verification completed"
        return 0
    else
        print_ansible_error "OpenShift project verification failed"
        return 1
    fi
}

# Function to run comprehensive validation using Ansible
run_comprehensive_validation_ansible() {
    local project_name="${1:-validation-test-$(date +%H%M%S)}"
    
    print_ansible_info "Running comprehensive validation via Ansible..."
    
    # Run multiple validation playbooks in sequence
    local playbooks=(
        "debug_servicenow_api.yml:ServiceNow API Validation"
        "oauth_status_summary.yml:OAuth Integration Status"
        "detailed_flow_validation.yml:Flow Designer Validation"
    )
    
    local success_count=0
    local total_count=${#playbooks[@]}
    
    for playbook_desc in "${playbooks[@]}"; do
        IFS=':' read -r playbook description <<< "$playbook_desc"
        
        if run_ansible_playbook "$playbook" "$description"; then
            ((success_count++))
        else
            print_ansible_warning "Validation step failed: $description"
        fi
    done
    
    print_ansible_info "Validation summary: $success_count/$total_count steps passed"
    
    if [ $success_count -eq $total_count ]; then
        print_ansible_success "All validation steps passed"
        return 0
    else
        print_ansible_warning "Some validation steps failed"
        return 1
    fi
}

# Function to get Ansible logs summary
get_ansible_logs_summary() {
    local max_logs="${1:-5}"
    
    print_ansible_info "Recent Ansible execution logs:"
    
    if [ -d "$ANSIBLE_LOG_DIR" ] && [ "$(ls -A "$ANSIBLE_LOG_DIR" 2>/dev/null)" ]; then
        ls -lt "$ANSIBLE_LOG_DIR"/*.log 2>/dev/null | head -"$max_logs" | while read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
    else
        print_ansible_info "No Ansible logs found"
    fi
}

# Function to clean up old Ansible logs
cleanup_ansible_logs() {
    local days_old="${1:-7}"
    
    print_ansible_info "Cleaning up Ansible logs older than $days_old days..."
    
    if [ -d "$ANSIBLE_LOG_DIR" ]; then
        find "$ANSIBLE_LOG_DIR" -name "*.log" -type f -mtime +$days_old -delete
        print_ansible_success "Old logs cleaned up"
    fi
}
