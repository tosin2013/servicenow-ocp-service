#!/bin/bash

# Live Site Link Testing Script for ServiceNow-OpenShift Documentation
# Tests all links on the deployed GitHub Pages site for functionality
# Author: Generated for ServiceNow-OCP Integration Project
# Usage: ./scripts/test-live-site-links.sh [--verbose] [--report-file output.json]

set -euo pipefail

# Configuration
SITE_URL="https://tosin2013.github.io/servicenow-ocp-service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$PROJECT_ROOT/docs/reports"
TEMP_DIR="/tmp/live-site-test-$$"

# Default settings
VERBOSE=false
REPORT_FILE="$REPORT_DIR/live-site-test-$TIMESTAMP.json"
MAX_CONCURRENT=5
TIMEOUT=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --report-file|-r)
            REPORT_FILE="$2"
            shift 2
            ;;
        --timeout|-t)
            TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --verbose, -v           Enable verbose output"
            echo "  --report-file, -r FILE  Specify report output file"
            echo "  --timeout, -t SECONDS   HTTP timeout (default: 10)"
            echo "  --help, -h              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Utility functions
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

# Create necessary directories
mkdir -p "$REPORT_DIR" "$TEMP_DIR"

# Initialize report structure
cat > "$REPORT_FILE" << EOF
{
  "test_run": {
    "timestamp": "$(date -Iseconds)",
    "site_url": "$SITE_URL",
    "timeout": $TIMEOUT,
    "max_concurrent": $MAX_CONCURRENT
  },
  "summary": {
    "total_pages": 0,
    "total_links": 0,
    "working_links": 0,
    "broken_links": 0,
    "warning_links": 0,
    "success_rate": 0.0
  },
  "pages_tested": [],
  "link_results": [],
  "broken_links": [],
  "warnings": []
}
EOF

log "🚀 Starting live site link testing for: $SITE_URL"

# Function to extract all links from a page
extract_links_from_page() {
    local page_url="$1"
    local page_file="$TEMP_DIR/$(basename "$page_url" .html).html"
    
    if $VERBOSE; then
        log "Fetching page: $page_url"
    fi
    
    # Download the page
    if curl -s --max-time "$TIMEOUT" "$page_url" > "$page_file" 2>/dev/null; then
        # Extract all href links
        grep -oP 'href="[^"]*"' "$page_file" 2>/dev/null | \
            sed 's/href="//g' | sed 's/"//g' | \
            grep -v '^#' | \
            grep -v '^javascript:' | \
            sort -u || true
    else
        log_error "Failed to fetch page: $page_url"
        return 1
    fi
}

# Function to test a single link
test_link() {
    local link="$1"
    local source_page="$2"
    local result_file="$TEMP_DIR/link_$(echo "$link" | md5sum | cut -d' ' -f1).json"
    
    # Convert relative links to absolute
    if [[ "$link" =~ ^/ ]]; then
        link="$SITE_URL$link"
    elif [[ ! "$link" =~ ^https?:// ]]; then
        # Handle relative links
        local base_url=$(dirname "$source_page")
        link="$base_url/$link"
    fi
    
    local start_time=$(date +%s.%N)
    local status_code
    local response_time
    local error_msg=""
    
    # Test the link
    if response=$(curl -s -w "%{http_code}|%{time_total}" --max-time "$TIMEOUT" -o /dev/null "$link" 2>&1); then
        status_code=$(echo "$response" | cut -d'|' -f1)
        response_time=$(echo "$response" | cut -d'|' -f2)
    else
        status_code="000"
        response_time="0"
        error_msg="Connection failed: $response"
    fi
    
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    # Determine link status
    local link_status="working"
    if [[ "$status_code" =~ ^[45] ]]; then
        link_status="broken"
    elif [[ "$status_code" == "000" ]] || [[ "$status_code" =~ ^3 ]]; then
        link_status="warning"
    fi
    
    # Create result JSON
    cat > "$result_file" << EOF
{
  "url": "$link",
  "source_page": "$source_page",
  "status_code": "$status_code",
  "response_time": "$response_time",
  "total_time": "$total_time",
  "status": "$link_status",
  "error": "$error_msg",
  "timestamp": "$(date -Iseconds)"
}
EOF
    
    if $VERBOSE; then
        case "$link_status" in
            "working")
                log_success "[$status_code] $link"
                ;;
            "broken")
                log_error "[$status_code] $link"
                ;;
            "warning")
                log_warning "[$status_code] $link"
                ;;
        esac
    fi
}

# Discover all pages on the site
log "🔍 Discovering pages on the site..."
PAGES_TO_TEST=()

# Start with the main page
PAGES_TO_TEST+=("$SITE_URL/")

# Add common documentation pages
COMMON_PAGES=(
    "adrs/"
    "tutorials/"
    "how-to/"
    "reference/"
    "explanation/"
    "tutorials/getting-started/"
    "end-to-end-test-guide/"
)

for page in "${COMMON_PAGES[@]}"; do
    PAGES_TO_TEST+=("$SITE_URL/$page")
done

log "📄 Testing ${#PAGES_TO_TEST[@]} pages for links..."

# Extract and test all links
ALL_LINKS=()
LINK_SOURCES=()

for page_url in "${PAGES_TO_TEST[@]}"; do
    if $VERBOSE; then
        log "Processing page: $page_url"
    fi
    
    # Extract links from this page
    page_links=$(extract_links_from_page "$page_url" || true)
    
    if [[ -n "$page_links" ]]; then
        while IFS= read -r link; do
            if [[ -n "$link" ]]; then
                ALL_LINKS+=("$link")
                LINK_SOURCES+=("$page_url")
            fi
        done <<< "$page_links"
    fi
done

# Remove duplicates while preserving source mapping
declare -A UNIQUE_LINKS
for i in "${!ALL_LINKS[@]}"; do
    link="${ALL_LINKS[$i]}"
    source="${LINK_SOURCES[$i]}"
    if [[ -z "${UNIQUE_LINKS[$link]:-}" ]]; then
        UNIQUE_LINKS["$link"]="$source"
    fi
done

log "🔗 Found ${#UNIQUE_LINKS[@]} unique links to test"

# Test all links with limited concurrency
PIDS=()
ACTIVE_JOBS=0

for link in "${!UNIQUE_LINKS[@]}"; do
    source_page="${UNIQUE_LINKS[$link]}"
    
    # Wait if we've reached max concurrent jobs
    while [[ $ACTIVE_JOBS -ge $MAX_CONCURRENT ]]; do
        for i in "${!PIDS[@]}"; do
            if ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
                unset "PIDS[$i]"
                ((ACTIVE_JOBS--))
            fi
        done
        sleep 0.1
    done
    
    # Start link test in background
    test_link "$link" "$source_page" &
    PIDS+=($!)
    ((ACTIVE_JOBS++))
    
    if ! $VERBOSE && [[ $((${#UNIQUE_LINKS[@]} % 10)) -eq 0 ]]; then
        echo -n "."
    fi
done

# Wait for all background jobs to complete
log "⏳ Waiting for all link tests to complete..."
for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

if ! $VERBOSE; then
    echo # New line after progress dots
fi

# Collect and analyze results
log "📊 Analyzing results..."

WORKING_COUNT=0
BROKEN_COUNT=0
WARNING_COUNT=0
TOTAL_COUNT=${#UNIQUE_LINKS[@]}

# Process all result files
for result_file in "$TEMP_DIR"/link_*.json; do
    if [[ -f "$result_file" ]]; then
        status=$(jq -r '.status' "$result_file" 2>/dev/null || echo "unknown")
        case "$status" in
            "working") ((WORKING_COUNT++)) ;;
            "broken") ((BROKEN_COUNT++)) ;;
            "warning") ((WARNING_COUNT++)) ;;
        esac
    fi
done

# Calculate success rate
SUCCESS_RATE=0
if [[ $TOTAL_COUNT -gt 0 ]]; then
    SUCCESS_RATE=$(echo "scale=2; $WORKING_COUNT * 100 / $TOTAL_COUNT" | bc -l 2>/dev/null || echo "0")
fi

# Update final report
jq --argjson total "$TOTAL_COUNT" \
   --argjson working "$WORKING_COUNT" \
   --argjson broken "$BROKEN_COUNT" \
   --argjson warning "$WARNING_COUNT" \
   --argjson success_rate "$SUCCESS_RATE" \
   '.summary.total_links = $total | 
    .summary.working_links = $working | 
    .summary.broken_links = $broken | 
    .summary.warning_links = $warning | 
    .summary.success_rate = $success_rate' \
   "$REPORT_FILE" > "$TEMP_DIR/final_report.json"

mv "$TEMP_DIR/final_report.json" "$REPORT_FILE"

# Display summary
echo
log "📋 LIVE SITE LINK TEST SUMMARY"
echo "=================================="
log_success "Total Links Tested: $TOTAL_COUNT"
log_success "Working Links: $WORKING_COUNT"
if [[ $BROKEN_COUNT -gt 0 ]]; then
    log_error "Broken Links: $BROKEN_COUNT"
else
    log_success "Broken Links: $BROKEN_COUNT"
fi
if [[ $WARNING_COUNT -gt 0 ]]; then
    log_warning "Warning Links: $WARNING_COUNT"
else
    log_success "Warning Links: $WARNING_COUNT"
fi
log "Success Rate: ${SUCCESS_RATE}%"
echo
log "📄 Detailed report saved to: $REPORT_FILE"

# Show broken links if any
if [[ $BROKEN_COUNT -gt 0 ]]; then
    echo
    log_error "BROKEN LINKS FOUND:"
    for result_file in "$TEMP_DIR"/link_*.json; do
        if [[ -f "$result_file" ]]; then
            status=$(jq -r '.status' "$result_file" 2>/dev/null || echo "unknown")
            if [[ "$status" == "broken" ]]; then
                url=$(jq -r '.url' "$result_file" 2>/dev/null || echo "unknown")
                status_code=$(jq -r '.status_code' "$result_file" 2>/dev/null || echo "unknown")
                echo "  ❌ [$status_code] $url"
            fi
        fi
    done
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Exit with appropriate code
if [[ $BROKEN_COUNT -gt 0 ]]; then
    log_error "❌ Live site has broken links!"
    exit 1
else
    log_success "✅ All links on live site are working!"
    exit 0
fi
