#!/bin/bash

# Comprehensive Site Validation Script
# Tests live GitHub Pages deployment and provides detailed diagnostics

set -e

SITE_URL="https://tosin2013.github.io/servicenow-ocp-service"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="docs/reports/site-validation-${TIMESTAMP}.json"

echo "🔍 COMPREHENSIVE SITE VALIDATION"
echo "================================="
echo "Site: $SITE_URL"
echo "Time: $(date)"
echo ""

# Create reports directory
mkdir -p docs/reports

# Initialize JSON report
cat > "$REPORT_FILE" << 'EOF'
{
  "validation_time": "",
  "site_url": "",
  "overall_status": "",
  "working_pages": [],
  "broken_pages": [],
  "build_info": {},
  "summary": {
    "total_tested": 0,
    "working": 0,
    "broken": 0,
    "success_rate": 0
  }
}
EOF

# Test URLs
declare -A test_urls=(
    ["Home"]="$SITE_URL/"
    ["Getting Started"]="$SITE_URL/GETTING_STARTED/"
    ["ADR-001"]="$SITE_URL/adrs/001-three-tier-orchestration-architecture/"
    ["ADR-016"]="$SITE_URL/adrs/016-documentation-link-validation-strategy/"
    ["Deployment Architecture"]="$SITE_URL/explanation/deployment-architecture/"
    ["User Workflows Analysis"]="$SITE_URL/explanation/user-workflows-analysis/"
    ["Ansible Vault Tutorial"]="$SITE_URL/tutorials/ansible-vault-configuration/"
    ["Link Validation Report"]="$SITE_URL/reference/link-validation-report/"
    ["Build Info"]="$SITE_URL/build-info.json"
)

working_count=0
broken_count=0
total_count=${#test_urls[@]}

echo "📊 TESTING ${total_count} CRITICAL PAGES"
echo "----------------------------------------"

working_pages=()
broken_pages=()

for name in "${!test_urls[@]}"; do
    url="${test_urls[$name]}"
    echo -n "Testing $name... "
    
    if http_code=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null); then
        if [[ "$http_code" == "200" ]]; then
            echo "✅ $http_code"
            working_pages+=("\"$name\": \"$url\"")
            ((working_count++))
        else
            echo "❌ $http_code"
            broken_pages+=("\"$name\": \"$url (HTTP $http_code)\"")
            ((broken_count++))
        fi
    else
        echo "❌ TIMEOUT"
        broken_pages+=("\"$name\": \"$url (TIMEOUT)\"")
        ((broken_count++))
    fi
done

echo ""
echo "📈 RESULTS SUMMARY"
echo "=================="
echo "✅ Working: $working_count/$total_count"
echo "❌ Broken:  $broken_count/$total_count"

success_rate=$(( (working_count * 100) / total_count ))
echo "📊 Success Rate: ${success_rate}%"

# Get build info
echo ""
echo "🏗️ BUILD INFORMATION"
echo "===================="
if build_info=$(timeout 5 curl -s "$SITE_URL/build-info.json" 2>/dev/null); then
    echo "$build_info" | jq . 2>/dev/null || echo "$build_info"
else
    echo "❌ Could not retrieve build information"
    build_info="{\"error\": \"Could not retrieve build info\"}"
fi

# Update JSON report
jq --arg timestamp "$(date -Iseconds)" \
   --arg site_url "$SITE_URL" \
   --arg overall_status "$([ $success_rate -ge 80 ] && echo 'GOOD' || echo 'NEEDS_ATTENTION')" \
   --argjson working_pages "{$(IFS=,; echo "${working_pages[*]}")}" \
   --argjson broken_pages "{$(IFS=,; echo "${broken_pages[*]}")}" \
   --argjson build_info "$build_info" \
   --arg total_tested "$total_count" \
   --arg working "$working_count" \
   --arg broken "$broken_count" \
   --arg success_rate "$success_rate" \
   '.validation_time = $timestamp |
    .site_url = $site_url |
    .overall_status = $overall_status |
    .working_pages = $working_pages |
    .broken_pages = $broken_pages |
    .build_info = $build_info |
    .summary.total_tested = ($total_tested | tonumber) |
    .summary.working = ($working | tonumber) |
    .summary.broken = ($broken | tonumber) |
    .summary.success_rate = ($success_rate | tonumber)' \
   "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"

echo ""
echo "📄 DETAILED REPORT SAVED: $REPORT_FILE"

# Final status
if [ $success_rate -ge 80 ]; then
    echo ""
    echo "🎉 OVERALL STATUS: GOOD (${success_rate}% success rate)"
    exit 0
else
    echo ""
    echo "⚠️  OVERALL STATUS: NEEDS ATTENTION (${success_rate}% success rate)"
    echo ""
    echo "🔧 RECOMMENDATIONS:"
    echo "- Check GitHub Actions deployment logs"
    echo "- Verify mkdocs.yml navigation configuration"
    echo "- Wait for GitHub Pages CDN propagation (5-10 minutes)"
    echo "- Compare local build with deployed site"
    exit 1
fi
