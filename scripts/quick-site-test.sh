#!/bin/bash

# Quick Live Site Test for ServiceNow-OpenShift Documentation
# Tests key pages and links on the deployed GitHub Pages site
# Author: Generated for ServiceNow-OCP Integration Project

set -euo pipefail

SITE_URL="https://tosin2013.github.io/servicenow-ocp-service"
TIMEOUT=10

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅${NC} $1"; }
log_warning() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"; }
log_error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"; }

# Test a single URL
test_url() {
    local url="$1"
    local description="$2"
    
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")
    
    case "$status_code" in
        200)
            log_success "$description: $status_code"
            return 0
            ;;
        404)
            log_error "$description: $status_code (Not Found)"
            return 1
            ;;
        000)
            log_error "$description: Connection failed"
            return 1
            ;;
        *)
            log_warning "$description: $status_code"
            return 0
            ;;
    esac
}

# Test content exists on page
test_content() {
    local url="$1"
    local search_text="$2"
    local description="$3"
    
    if curl -s --max-time "$TIMEOUT" "$url" 2>/dev/null | grep -q "$search_text"; then
        log_success "$description: Content found"
        return 0
    else
        log_error "$description: Content missing"
        return 1
    fi
}

log "🚀 Quick Live Site Test for: $SITE_URL"
echo "=================================================="

TOTAL_TESTS=0
PASSED_TESTS=0

# Test main pages
MAIN_PAGES=(
    "$SITE_URL/|Home Page"
    "$SITE_URL/adrs/|ADRs Index"
    "$SITE_URL/tutorials/|Tutorials Index"
    "$SITE_URL/reference/|Reference Index"
    "$SITE_URL/end-to-end-test-guide/|End-to-End Test Guide"
)

log "📄 Testing main pages..."
for page_info in "${MAIN_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test specific ADR pages
log "📋 Testing ADR pages..."
ADR_PAGES=(
    "$SITE_URL/adrs/001-three-tier-orchestration-architecture/|ADR-001"
    "$SITE_URL/adrs/016-documentation-link-validation-strategy/|ADR-016 (Link Validation)"
)

for page_info in "${ADR_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test critical content exists
log "🔍 Testing critical content..."
CONTENT_TESTS=(
    "$SITE_URL/|ServiceNow-OpenShift Integration|Project Title"
    "$SITE_URL/adrs/|ADR-016|Link Validation ADR Listed"
    "$SITE_URL/end-to-end-test-guide/|95% confidence score|Test Results"
)

for content_info in "${CONTENT_TESTS[@]}"; do
    IFS='|' read -r url search_text description <<< "$content_info"
    ((TOTAL_TESTS++))
    if test_content "$url" "$search_text" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test some external links that should work
log "🌐 Testing sample external links..."
EXTERNAL_LINKS=(
    "https://github.com/tosin2013/servicenow-ocp-service|GitHub Repository"
    "https://www.redhat.com/|Red Hat (Sample External)"
)

for link_info in "${EXTERNAL_LINKS[@]}"; do
    IFS='|' read -r url description <<< "$link_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Calculate success rate
SUCCESS_RATE=0
if [[ $TOTAL_TESTS -gt 0 ]]; then
    SUCCESS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
fi

echo
echo "=================================================="
log "📊 QUICK SITE TEST SUMMARY"
echo "=================================================="
log_success "Total Tests: $TOTAL_TESTS"
log_success "Passed Tests: $PASSED_TESTS"
log_success "Failed Tests: $((TOTAL_TESTS - PASSED_TESTS))"
log "Success Rate: ${SUCCESS_RATE}%"
echo

if [[ $SUCCESS_RATE -ge 90 ]]; then
    log_success "🎉 Site is working excellently! ($SUCCESS_RATE% success rate)"
    exit 0
elif [[ $SUCCESS_RATE -ge 75 ]]; then
    log_warning "⚠️ Site is mostly working but has some issues ($SUCCESS_RATE% success rate)"
    exit 0
else
    log_error "❌ Site has significant issues ($SUCCESS_RATE% success rate)"
    exit 1
fi
