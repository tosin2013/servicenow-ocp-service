#!/bin/bash
#
# 🔍 AAP (Ansible Automation Platform) Monitoring Utility - SECURE VERSION
# Real-time monitoring of AAP jobs and execution status
# Uses vault configuration for credentials
#

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
if [ -z "${aap_url:-}" ] || [ -z "${vault_aap_token:-}" ]; then
    echo "❌ Error: Required AAP configuration not found in vault"
    echo "Please ensure aap_url and vault_aap_token are configured in your vault file."
    exit 1
fi

# Configuration from vault
AAP_URL="$aap_url"
AAP_TOKEN="$vault_aap_token"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

#
# Display Functions - Consistent formatting for all output
#

# Print informational messages with blue info icon
# Usage: print_info "message"
# Parameters: $1 - message to display
print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Print success messages with green checkmark
# Usage: print_success "message"
# Parameters: $1 - success message to display
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Print error messages with red X mark
# Usage: print_error "message"
# Parameters: $1 - error message to display
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Print warning messages with yellow warning icon
# Usage: print_warning "message"
# Parameters: $1 - warning message to display
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

#
# AAP API Integration Functions
#

# Make authenticated API calls to Ansible Automation Platform
# Usage: call_aap_api "GET" "/api/v2/jobs/"
# Parameters:
#   $1 - HTTP method (GET, POST, etc.)
#   $2 - API endpoint path
# Returns: JSON response from AAP API
# Dependencies: Requires AAP_URL and AAP_TOKEN to be set
call_aap_api() {
    local method="$1"
    local endpoint="$2"
    
    if ! curl -s -k -H "Authorization: Bearer $AAP_TOKEN" \
         -X "$method" \
         "${AAP_URL}${endpoint}" 2>/dev/null; then
        print_error "Failed to call AAP API: $endpoint"
        return 1
    fi
}

# Test connectivity to Ansible Automation Platform
# Usage: test_aap_connection
# Returns: 0 if successful, 1 if failed
# Side Effects: Displays connection status messages
# Dependencies: Requires AAP_URL and AAP_TOKEN to be set
test_aap_connection() {
    print_info "Testing AAP connection..."

    if call_aap_api "GET" "/api/v2/me/" >/dev/null; then
        print_success "AAP connection successful"
        return 0
    else
        print_error "AAP connection failed"
        print_info "Please check:"
        print_info "  - AAP URL: $AAP_URL"
        print_info "  - AAP token validity"
        print_info "  - Network connectivity"
        return 1
    fi
}

# Display recent AAP job executions with status and details
# Usage: monitor_recent_jobs [limit]
# Parameters:
#   $1 - Number of jobs to display (optional, default: 10)
# Returns: 0 if successful, 1 if failed
# Output: Formatted table of recent jobs with ID, name, status, and timestamps
monitor_recent_jobs() {
    local limit="${1:-10}"

    print_header "🔍 Recent AAP Jobs (Last $limit)"
    
    if ! test_aap_connection; then
        return 1
    fi
    
    local response
    if response=$(call_aap_api "GET" "/api/v2/jobs/?page_size=$limit&order_by=-created"); then
        echo "$response" | jq -r '
            .results[] | 
            "\(.id) | \(.name) | \(.status) | \(.created) | \(.finished // "running")"
        ' | while IFS='|' read -r id name status created finished; do
            case "$status" in
                "successful")
                    echo -e "${GREEN}✅ Job $id: $name ($status)${NC}"
                    ;;
                "failed")
                    echo -e "${RED}❌ Job $id: $name ($status)${NC}"
                    ;;
                "running")
                    echo -e "${YELLOW}🔄 Job $id: $name ($status)${NC}"
                    ;;
                *)
                    echo -e "${CYAN}ℹ️  Job $id: $name ($status)${NC}"
                    ;;
            esac
            echo -e "   Created: $created | Finished: $finished"
            echo ""
        done
    else
        print_error "Failed to retrieve recent jobs"
        return 1
    fi
}

monitor_job() {
    local job_id="$1"
    
    print_header "🔍 AAP Job Details: $job_id"
    
    if ! test_aap_connection; then
        return 1
    fi
    
    local response
    if response=$(call_aap_api "GET" "/api/v2/jobs/$job_id/"); then
        echo "$response" | jq -r '
            "Job ID: \(.id)",
            "Name: \(.name)",
            "Status: \(.status)",
            "Created: \(.created)",
            "Started: \(.started // "Not started")",
            "Finished: \(.finished // "Not finished")",
            "Elapsed: \(.elapsed) seconds",
            "Job Template: \(.job_template_name)",
            "Inventory: \(.inventory_name)",
            "Project: \(.project_name)"
        ' | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
        
        # Show job output if available
        print_info "Fetching job output..."
        if call_aap_api "GET" "/api/v2/jobs/$job_id/stdout/?format=txt" | head -20; then
            echo -e "\n${YELLOW}(Showing first 20 lines of output)${NC}"
        fi
    else
        print_error "Failed to retrieve job details for job $job_id"
        return 1
    fi
}

monitor_openshift_jobs() {
    print_header "🔍 OpenShift-Related AAP Jobs"
    
    if ! test_aap_connection; then
        return 1
    fi
    
    local response
    if response=$(call_aap_api "GET" "/api/v2/jobs/?search=openshift&page_size=10"); then
        echo "$response" | jq -r '
            .results[] | 
            "\(.id) | \(.name) | \(.status) | \(.created)"
        ' | while IFS='|' read -r id name status created; do
            case "$status" in
                "successful")
                    echo -e "${GREEN}✅ Job $id: $name${NC}"
                    ;;
                "failed")
                    echo -e "${RED}❌ Job $id: $name${NC}"
                    ;;
                "running")
                    echo -e "${YELLOW}🔄 Job $id: $name${NC}"
                    ;;
                *)
                    echo -e "${CYAN}ℹ️  Job $id: $name${NC}"
                    ;;
            esac
            echo -e "   Created: $created"
            echo ""
        done
    else
        print_error "Failed to retrieve OpenShift jobs"
        return 1
    fi
}

watch_job() {
    local job_id="$1"
    local interval="${2:-10}"
    
    print_header "👀 Watching AAP Job: $job_id (Refresh every ${interval}s)"
    print_info "Press Ctrl+C to stop watching"
    
    while true; do
        clear
        monitor_job "$job_id"
        echo -e "\n${YELLOW}Refreshing in ${interval} seconds...${NC}"
        sleep "$interval"
    done
}

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  jobs [LIMIT]             Show recent AAP jobs"
    echo "  job <JOB_ID>             Monitor specific job"
    echo "  openshift                Show OpenShift-related jobs"
    echo "  watch <JOB_ID> [INTERVAL] Watch job in real-time"
    echo "  test                     Test AAP connection"
    echo ""
    echo "Examples:"
    echo "  $0 jobs 5"
    echo "  $0 job 61"
    echo "  $0 openshift"
    echo "  $0 watch 61 5"
    echo "  $0 test"
}

main() {
    case "${1:-}" in
        "jobs")
            monitor_recent_jobs "${2:-10}"
            ;;
        "job")
            if [ $# -lt 2 ]; then
                echo "Error: Job ID required"
                usage
                exit 1
            fi
            monitor_job "$2"
            ;;
        "openshift")
            monitor_openshift_jobs
            ;;
        "watch")
            if [ $# -lt 2 ]; then
                echo "Error: Job ID required for watch mode"
                usage
                exit 1
            fi
            watch_job "$2" "${3:-10}"
            ;;
        "test")
            test_aap_connection
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
