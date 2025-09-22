#!/bin/bash

# ServiceNow-OpenShift Integration Environment Cleanup Script
# Uses direct APIs and commands for efficient cleanup
#
# Usage:
# ./scripts/cleanup-environment.sh [mode]
# 
# Modes:
#   dry-run    - Show what would be cleaned (default)
#   safe       - Clean test requests and projects only
#   aggressive - Also clean failed AAP jobs
#   full       - Clean everything including catalog items

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_FILE="$PROJECT_ROOT/.vault_pass"
VAULT_YML="$PROJECT_ROOT/ansible/group_vars/all/vault.yml"

# Default mode
MODE="${1:-dry-run}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "\n${BLUE}🔍 $1${NC}"
    echo "============================================================"
}

# Get ServiceNow credentials
get_servicenow_password() {
    if [[ ! -f "$VAULT_FILE" ]]; then
        log_error "Vault password file not found: $VAULT_FILE"
        exit 1
    fi

    if [[ ! -f "$VAULT_YML" ]]; then
        log_error "Vault YAML file not found: $VAULT_YML"
        exit 1
    fi

    ansible-vault view "$VAULT_YML" --vault-password-file "$VAULT_FILE" | \
        grep "vault_servicenow_password:" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'
}

# Get AAP token
get_aap_token() {
    ansible-vault view "$VAULT_YML" --vault-password-file "$VAULT_FILE" | \
        grep "vault_aap_token:" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'
}

# Main cleanup function
main() {
    log_header "ServiceNow-OpenShift Integration Environment Cleanup"
    echo "Mode: $MODE"
    echo "Date: $(date)"
    echo ""
    
    # Get credentials
    log_info "Getting credentials from vault..."
    SERVICENOW_PASSWORD=$(get_servicenow_password)
    AAP_TOKEN=$(get_aap_token)
    
    if [[ -z "$SERVICENOW_PASSWORD" ]]; then
        log_error "Failed to get ServiceNow password from vault"
        exit 1
    fi
    
    if [[ -z "$AAP_TOKEN" ]]; then
        log_error "Failed to get AAP token from vault"
        exit 1
    fi
    
    log_success "Credentials retrieved successfully"
    
    # Phase 1: ServiceNow Requests Cleanup
    cleanup_servicenow_requests
    
    # Phase 2: AAP Jobs Cleanup
    if [[ "$MODE" == "aggressive" || "$MODE" == "full" ]]; then
        cleanup_aap_jobs
    fi
    
    # Phase 3: OpenShift Projects Cleanup
    cleanup_openshift_projects
    
    # Phase 4: ServiceNow Catalog Cleanup (full mode only)
    if [[ "$MODE" == "full" ]]; then
        cleanup_servicenow_catalog
    fi
    
    # Summary
    log_header "Cleanup Summary"
    log_success "Environment cleanup completed in $MODE mode"
    
    if [[ "$MODE" == "dry-run" ]]; then
        log_warning "This was a dry run. No actual changes were made."
        echo ""
        echo "To perform actual cleanup:"
        echo "  Safe mode:       ./scripts/cleanup-environment.sh safe"
        echo "  Aggressive mode: ./scripts/cleanup-environment.sh aggressive"
        echo "  Full cleanup:    ./scripts/cleanup-environment.sh full"
    fi
}

# ServiceNow requests cleanup
cleanup_servicenow_requests() {
    log_header "Phase 1: ServiceNow Requests Cleanup"
    
    # Get recent test requests
    log_info "Fetching recent ServiceNow requests..."
    
    local requests_json
    requests_json=$(curl -s -u "admin:$SERVICENOW_PASSWORD" \
        "https://dev295398.service-now.com/api/now/table/sc_request?sysparm_limit=50&sysparm_fields=number,short_description,state,sys_created_on,sys_id")
    
    if [[ $(echo "$requests_json" | jq -r '.error // empty') ]]; then
        log_error "Failed to fetch ServiceNow requests: $(echo "$requests_json" | jq -r '.error.message')"
        return 1
    fi
    
    # Filter test requests
    local test_requests
    test_requests=$(echo "$requests_json" | jq -r '.result[] | select(.short_description | test("Test|ServiceNow Real Integration|test")) | "\(.number):\(.sys_id):\(.short_description):\(.state)"')
    
    if [[ -z "$test_requests" ]]; then
        log_info "No test requests found to clean up"
        return 0
    fi
    
    echo "Found test requests:"
    echo "$test_requests" | while IFS=':' read -r number sys_id description state; do
        echo "  • $number: $description (State: $state)"
    done
    
    if [[ "$MODE" == "dry-run" ]]; then
        log_warning "Would cancel $(echo "$test_requests" | wc -l) test requests"
        return 0
    fi
    
    # Cancel test requests
    log_info "Cancelling test requests..."
    echo "$test_requests" | while IFS=':' read -r number sys_id description state; do
        if [[ "$state" == "1" || "$state" == "2" ]]; then  # New or In Progress
            log_info "Cancelling request $number..."
            curl -s -u "admin:$SERVICENOW_PASSWORD" \
                -X PUT \
                -H "Content-Type: application/json" \
                -d '{"state":"7","work_notes":"Cancelled during environment cleanup"}' \
                "https://dev295398.service-now.com/api/now/table/sc_request/$sys_id" > /dev/null
            log_success "Cancelled $number"
        fi
    done
}

# AAP jobs cleanup
cleanup_aap_jobs() {
    log_header "Phase 2: AAP Jobs Cleanup"
    
    log_info "Fetching AAP jobs..."
    
    local jobs_json
    jobs_json=$(curl -s -H "Authorization: Bearer $AAP_TOKEN" \
        "https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/api/v2/jobs/?page_size=50&order_by=-created")
    
    if [[ $(echo "$jobs_json" | jq -r '.detail // empty') ]]; then
        log_error "Failed to fetch AAP jobs: $(echo "$jobs_json" | jq -r '.detail')"
        return 1
    fi
    
    local failed_jobs
    failed_jobs=$(echo "$jobs_json" | jq -r '.results[] | select(.status == "failed") | .id')
    
    local failed_count
    failed_count=$(echo "$failed_jobs" | wc -w)
    
    log_info "Found $failed_count failed jobs"
    
    if [[ "$MODE" == "dry-run" ]]; then
        log_warning "Would delete $failed_count failed jobs (keeping last 5 for debugging)"
        return 0
    fi
    
    # Delete failed jobs (keep last 5)
    local jobs_to_delete
    jobs_to_delete=$(echo "$failed_jobs" | head -n -5)
    
    if [[ -n "$jobs_to_delete" ]]; then
        log_info "Deleting old failed jobs..."
        for job_id in $jobs_to_delete; do
            curl -s -X DELETE \
                -H "Authorization: Bearer $AAP_TOKEN" \
                "https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/api/v2/jobs/$job_id/" > /dev/null
            log_success "Deleted job $job_id"
        done
    else
        log_info "No old failed jobs to delete (keeping last 5)"
    fi
}

# OpenShift projects cleanup
cleanup_openshift_projects() {
    log_header "Phase 3: OpenShift Projects Cleanup"
    
    log_info "Fetching ServiceNow-created OpenShift projects..."
    
    local servicenow_projects
    servicenow_projects=$(oc get projects -o name | grep -E "(servicenow-|test-)" | sed 's|project.project.openshift.io/||')
    
    if [[ -z "$servicenow_projects" ]]; then
        log_info "No ServiceNow projects found to clean up"
        return 0
    fi
    
    echo "Found ServiceNow projects:"
    for project in $servicenow_projects; do
        echo "  • $project"
    done
    
    if [[ "$MODE" == "dry-run" ]]; then
        log_warning "Would delete $(echo "$servicenow_projects" | wc -w) ServiceNow projects"
        return 0
    fi
    
    # Delete projects
    log_info "Deleting ServiceNow projects..."
    for project in $servicenow_projects; do
        # Skip production projects
        if [[ "$project" =~ prod|production ]]; then
            log_warning "Skipping production project: $project"
            continue
        fi
        
        log_info "Deleting project $project..."
        oc delete project "$project" --ignore-not-found=true
        log_success "Deleted project $project"
    done
    
    # Wait for deletion
    if [[ -n "$servicenow_projects" ]]; then
        log_info "Waiting for project deletion to complete..."
        sleep 10
        
        for project in $servicenow_projects; do
            if [[ "$project" =~ prod|production ]]; then
                continue
            fi
            
            local retries=0
            while oc get project "$project" &>/dev/null && [[ $retries -lt 30 ]]; do
                sleep 5
                ((retries++))
            done
            
            if oc get project "$project" &>/dev/null; then
                log_warning "Project $project is still being deleted..."
            else
                log_success "Project $project deletion completed"
            fi
        done
    fi
}

# ServiceNow catalog cleanup
cleanup_servicenow_catalog() {
    log_header "Phase 4: ServiceNow Catalog Cleanup"
    
    log_info "Fetching test catalog items..."
    
    local catalog_json
    catalog_json=$(curl -s -u "admin:$SERVICENOW_PASSWORD" \
        "https://dev295398.service-now.com/api/now/table/sc_cat_item?sysparm_query=nameLIKETest&sysparm_fields=sys_id,name,active")
    
    if [[ $(echo "$catalog_json" | jq -r '.error // empty') ]]; then
        log_error "Failed to fetch catalog items: $(echo "$catalog_json" | jq -r '.error.message')"
        return 1
    fi
    
    local test_items
    test_items=$(echo "$catalog_json" | jq -r '.result[] | select(.active == "true") | "\(.sys_id):\(.name)"')
    
    if [[ -z "$test_items" ]]; then
        log_info "No test catalog items found to clean up"
        return 0
    fi
    
    echo "Found test catalog items:"
    echo "$test_items" | while IFS=':' read -r sys_id name; do
        echo "  • $name"
    done
    
    if [[ "$MODE" == "dry-run" ]]; then
        log_warning "Would deactivate $(echo "$test_items" | wc -l) test catalog items"
        return 0
    fi
    
    # Deactivate test items
    log_info "Deactivating test catalog items..."
    echo "$test_items" | while IFS=':' read -r sys_id name; do
        log_info "Deactivating $name..."
        curl -s -u "admin:$SERVICENOW_PASSWORD" \
            -X PUT \
            -H "Content-Type: application/json" \
            -d '{"active":"false","comments":"Deactivated during environment cleanup"}' \
            "https://dev295398.service-now.com/api/now/table/sc_cat_item/$sys_id" > /dev/null
        log_success "Deactivated $name"
    done
}

# Run main function
main "$@"
