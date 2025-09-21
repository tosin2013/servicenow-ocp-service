# Link Monitoring and Alerting Setup

**Purpose**: Configure ongoing monitoring and alerting for documentation link health  
**Related**: [ADR-016: Documentation Link Validation Strategy](../adrs/016-documentation-link-validation-strategy.md)

## Monitoring Strategy

### 🔄 Automated Monitoring Schedule

**GitHub Actions Workflow** (`.github/workflows/documentation-validation.yml`):
- **Weekly**: Full link validation every Sunday at 2 AM UTC
- **On Changes**: Validation triggered by documentation file changes
- **Manual**: On-demand validation with configurable options

**Monitoring Frequency**:
```yaml
schedule:
  # Weekly comprehensive check
  - cron: '0 2 * * 0'  # Sundays at 2 AM UTC
  
  # Optional: Daily quick external check
  # - cron: '0 6 * * *'  # Daily at 6 AM UTC
```

### 📊 Monitoring Metrics

**Link Health Metrics**:
- Total links monitored
- Broken link count and percentage
- Warning link count (timeouts, slow responses)
- Response time trends for critical links
- Link failure patterns by domain

**Documentation Health Metrics**:
- Files with broken links
- Most problematic domains
- Link validation success rate over time
- Time to fix broken links

## Alert Configuration

### 🚨 Immediate Alerts

**Critical Broken Links** (Auto-created GitHub Issues):
```yaml
# Triggered when scheduled validation fails
- name: Create issue for broken links
  if: github.event_name == 'schedule' && failure()
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.create({
        title: "🔗 Broken Links Detected - ${date}",
        labels: ['documentation', 'maintenance', 'broken-links'],
        body: "Automated link validation detected broken links..."
      });
```

**Alert Conditions**:
- Any broken links in critical ADR files
- More than 5% of total links broken
- ServiceNow documentation mass failures
- Internal link failures (immediate fix required)

### 📧 Notification Channels

**GitHub Issues** (Primary):
- Automatic issue creation for broken links
- Labels: `documentation`, `maintenance`, `broken-links`
- Assigned to documentation maintainers
- Includes direct links to validation reports

**Pull Request Comments** (Secondary):
- Validation results posted to PRs
- Prevents merging with broken links
- Links to detailed reports and fix guidance

**Optional Integrations**:
```yaml
# Slack notification (if configured)
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: "Documentation link validation failed"
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}

# Email notification (if configured)  
- name: Send email alert
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    subject: "Documentation Link Validation Failed"
    body: "Broken links detected in documentation"
```

## Monitoring Dashboard

### 📈 Link Health Dashboard

**GitHub Repository Insights**:
- Issues labeled `broken-links` for current problems
- Workflow run history for validation trends
- Artifact downloads for detailed reports

**Custom Dashboard Options**:
```bash
# Generate link health report
./docs/scripts/generate-link-health-report.sh

# Output: docs/reports/link-health-dashboard.html
# Includes:
# - Link validation trends over time
# - Most problematic domains
# - Response time analysis
# - Fix time metrics
```

### 📊 Metrics Collection

**Validation Report Structure**:
```json
{
  "timestamp": "2025-09-21T18:25:00Z",
  "summary": {
    "totalLinks": 206,
    "validLinks": 164,
    "brokenLinks": 24,
    "warningLinks": 18,
    "validationTime": 63918
  },
  "trends": {
    "brokenLinkTrend": "increasing",
    "responseTimeTrend": "stable",
    "fixRate": "85%"
  },
  "alerts": [
    {
      "type": "critical",
      "message": "ServiceNow docs timeout rate > 50%",
      "recommendation": "Switch to community links"
    }
  ]
}
```

## Response Procedures

### 🚨 Critical Link Failures

**Immediate Response (< 2 hours)**:
1. **Assess Impact**: Determine if broken links affect critical user workflows
2. **Quick Fix**: Replace with working alternatives if available
3. **Document**: Update GitHub issue with temporary fix status
4. **Communicate**: Notify team if widespread documentation impact

**Example Quick Fix**:
```bash
# Replace broken ServiceNow link with community alternative
sed -i 's|docs.servicenow.com/bundle/vancouver-platform-administration/page/administer/business-rules/concept/c_BusinessRules.html|community.servicenow.com/community?id=community_search&q=business+rules|g' docs/content/adrs/013-pdi-workaround-strategy-for-development.md
```

### 🔧 Systematic Link Maintenance

**Weekly Maintenance Process**:
1. **Review Reports**: Analyze weekly validation results
2. **Prioritize Fixes**: Focus on critical ADRs and user-facing guides
3. **Update Links**: Replace broken links with current alternatives
4. **Verify Fixes**: Run validation to confirm repairs
5. **Document Changes**: Update changelog and close related issues

**Monthly Link Audit**:
1. **Trend Analysis**: Review link health trends over past month
2. **Domain Assessment**: Identify problematic domains for replacement
3. **Strategy Updates**: Adjust link selection strategy based on patterns
4. **Tool Updates**: Update validation tools and configurations

## Monitoring Tools Integration

### 🔧 External Monitoring Services

**Optional: UptimeRobot Integration**:
```bash
# Monitor critical external links independently
# Set up monitors for:
# - https://docs.servicenow.com (primary ServiceNow docs)
# - https://docs.openshift.com (primary OpenShift docs)  
# - https://www.keycloak.org (primary Keycloak docs)
# - https://docs.ansible.com (primary Ansible docs)
```

**Optional: Pingdom Integration**:
- Monitor response times for frequently referenced domains
- Alert on significant response time degradation
- Track availability trends for critical documentation sources

### 📊 Analytics Integration

**Google Analytics (if documentation site deployed)**:
- Track 404 errors from documentation links
- Monitor user behavior when encountering broken links
- Identify most-accessed external references

**Custom Analytics**:
```bash
# Generate link usage analytics
./docs/scripts/analyze-link-usage.sh
# Output: Most referenced domains, link click patterns, etc.
```

## Maintenance Schedule

### 📅 Regular Maintenance Tasks

**Daily** (Automated):
- Monitor GitHub Actions workflow results
- Check for new broken link issues

**Weekly** (Automated + Manual Review):
- Comprehensive link validation run
- Review and triage any new issues
- Quick fixes for critical broken links

**Monthly** (Manual):
- Comprehensive link audit and cleanup
- Update link selection strategy
- Review monitoring effectiveness
- Update validation tools and configurations

**Quarterly** (Manual):
- Full documentation link review
- Update ADR-016 based on lessons learned
- Assess and improve monitoring strategy
- Team training on link validation processes

### 🎯 Success Metrics

**Target Metrics**:
- < 2% broken links at any time
- < 24 hours average time to fix critical broken links
- > 95% link validation success rate
- Zero broken links in critical ADR files

**Monitoring KPIs**:
- Link validation success rate trend
- Mean time to repair (MTTR) for broken links
- User-reported broken link incidents (should be zero)
- Documentation quality score based on link health

---

**Remember**: Proactive monitoring prevents user frustration and maintains professional documentation standards. The goal is to catch and fix link issues before users encounter them.
