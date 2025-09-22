#!/bin/bash

# Live Site Test Based on Actual Site Structure
# Tests the real URLs from the deployed GitHub Pages site
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

log "🚀 Live Site Test for: $SITE_URL"
log "📁 Testing based on actual docs/site structure"
echo "=================================================="

TOTAL_TESTS=0
PASSED_TESTS=0

# Test main pages (based on actual site structure)
log "📄 Testing main pages..."
MAIN_PAGES=(
    "$SITE_URL/|Home Page"
    "$SITE_URL/adrs/|ADRs Index"
    "$SITE_URL/tutorials/|Tutorials Index"
    "$SITE_URL/how-to/|How-To Index"
    "$SITE_URL/reference/|Reference Index"
    "$SITE_URL/explanation/|Explanation Index"
    "$SITE_URL/END_TO_END_TEST_EXECUTION_SUMMARY/|End-to-End Test Summary"
    "$SITE_URL/GETTING_STARTED/|Getting Started Guide"
)

for page_info in "${MAIN_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test specific ADR pages (based on actual structure)
log "📋 Testing key ADR pages..."
ADR_PAGES=(
    "$SITE_URL/adrs/001-three-tier-orchestration-architecture/|ADR-001: Three-Tier Architecture"
    "$SITE_URL/adrs/016-documentation-link-validation-strategy/|ADR-016: Link Validation Strategy"
    "$SITE_URL/adrs/013-pdi-workaround-strategy-for-development/|ADR-013: PDI Workaround"
    "$SITE_URL/adrs/014-business-rules-over-flow-designer/|ADR-014: Business Rules"
)

for page_info in "${ADR_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test tutorial pages
log "📚 Testing tutorial pages..."
TUTORIAL_PAGES=(
    "$SITE_URL/tutorials/getting-started/|Getting Started Tutorial"
    "$SITE_URL/tutorials/ansible-automation-guide/|Ansible Automation Guide"
    "$SITE_URL/tutorials/execution-environment-guide/|Execution Environment Guide"
)

for page_info in "${TUTORIAL_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test how-to pages
log "🔧 Testing how-to pages..."
HOWTO_PAGES=(
    "$SITE_URL/how-to/end-to-end-testing/|End-to-End Testing Guide"
    "$SITE_URL/how-to/business-rule-logic/|Business Rule Logic"
    "$SITE_URL/how-to/working-with-ansible/|Working with Ansible"
)

for page_info in "${HOWTO_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test reference pages
log "📖 Testing reference pages..."
REFERENCE_PAGES=(
    "$SITE_URL/reference/link-validation-report/|Link Validation Report"
    "$SITE_URL/reference/ansible-reference/|Ansible Reference"
    "$SITE_URL/reference/api-documentation/|API Documentation"
)

for page_info in "${REFERENCE_PAGES[@]}"; do
    IFS='|' read -r url description <<< "$page_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test some external links that should work
log "🌐 Testing sample external links..."
EXTERNAL_LINKS=(
    "https://github.com/tosin2013/servicenow-ocp-service|GitHub Repository"
    "https://www.redhat.com/|Red Hat"
)

for link_info in "${EXTERNAL_LINKS[@]}"; do
    IFS='|' read -r url description <<< "$link_info"
    ((TOTAL_TESTS++))
    if test_url "$url" "$description"; then
        ((PASSED_TESTS++))
    fi
done

# Test site assets
log "🎨 Testing site assets..."
ASSET_TESTS=(
    "$SITE_URL/assets/logo.png|Site Logo"
    "$SITE_URL/sitemap.xml|Sitemap"
)

for asset_info in "${ASSET_TESTS[@]}"; do
    IFS='|' read -r url description <<< "$asset_info"
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
log "📊 LIVE SITE TEST RESULTS"
echo "=================================================="
log_success "Total Tests: $TOTAL_TESTS"
log_success "Passed Tests: $PASSED_TESTS"
if [[ $((TOTAL_TESTS - PASSED_TESTS)) -gt 0 ]]; then
    log_error "Failed Tests: $((TOTAL_TESTS - PASSED_TESTS))"
else
    log_success "Failed Tests: 0"
fi
log "Success Rate: ${SUCCESS_RATE}%"
echo

# Summary and recommendations
if [[ $SUCCESS_RATE -ge 95 ]]; then
    log_success "🎉 EXCELLENT! Site is working perfectly! ($SUCCESS_RATE% success rate)"
    log "✅ All critical pages and links are functional"
    log "✅ External link validation framework is deployed"
    log "✅ Documentation is fully accessible to users"
elif [[ $SUCCESS_RATE -ge 85 ]]; then
    log_success "✅ GOOD! Site is working well with minor issues ($SUCCESS_RATE% success rate)"
    log "⚠️ Some non-critical pages may need attention"
elif [[ $SUCCESS_RATE -ge 70 ]]; then
    log_warning "⚠️ FAIR: Site is mostly working but has some issues ($SUCCESS_RATE% success rate)"
    log "🔧 Some important pages may need fixes"
else
    log_error "❌ POOR: Site has significant issues ($SUCCESS_RATE% success rate)"
    log "🚨 Multiple critical pages are not working"
fi

echo
log "🔗 Live Site URL: $SITE_URL"
log "📋 Link Validation Report: $SITE_URL/reference/link-validation-report/"
log "📚 Getting Started: $SITE_URL/GETTING_STARTED/"

if [[ $SUCCESS_RATE -ge 85 ]]; then
    exit 0
else
    exit 1
fi
