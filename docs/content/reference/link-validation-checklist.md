# Documentation Link Validation Checklist

**Purpose**: Ensure all documentation links are valid, reliable, and follow project standards before committing changes.

**Related**: [ADR-016: Documentation Link Validation Strategy](../adrs/016-documentation-link-validation-strategy.md)

## Pre-Commit Checklist

### ✅ Automated Validation

**Run Link Validation Script:**
```bash
# From project root
./docs/scripts/validate-links.sh

# For CI/CD integration (fails on broken links)
./docs/scripts/validate-links.sh --fail-on-broken

# Quick external-only check
./docs/scripts/validate-links.sh --external-only --timeout 10
```

**Expected Results:**
- [ ] No broken external links (HTTP 4xx/5xx errors)
- [ ] No broken internal links (missing files)
- [ ] No broken anchor links (missing fragments)
- [ ] All warnings reviewed and addressed

### ✅ Manual Link Quality Review

**External Links:**
- [ ] **Official Documentation Preferred**: Use vendor official docs over blog posts
- [ ] **Stable URLs**: Avoid version-specific or temporary URLs
- [ ] **Accessibility**: Links work without authentication or special access
- [ ] **Relevance**: Links directly support the documentation content
- [ ] **Fallback References**: Critical concepts have alternative sources

**Internal Links:**
- [ ] **Relative Paths**: Use relative paths for internal references
- [ ] **File Existence**: All referenced files exist in the repository
- [ ] **Consistent Structure**: Follow established documentation hierarchy
- [ ] **Cross-References**: Bidirectional links are properly maintained

### ✅ Content-Specific Validation

**For ADR Documents:**
- [ ] **Technical Standards**: Links to official specifications (RFC, W3C, etc.)
- [ ] **Vendor Documentation**: Official product documentation over community posts
- [ ] **Security References**: OWASP, NIST, and other authoritative security sources
- [ ] **Compliance Standards**: Official compliance framework documentation

**For Tutorials and Guides:**
- [ ] **Step-by-Step Accuracy**: All linked resources support the tutorial flow
- [ ] **Version Compatibility**: Links work with documented software versions
- [ ] **Prerequisites**: All prerequisite links are accessible and current

**For Reference Documentation:**
- [ ] **API Documentation**: Links to current API versions
- [ ] **Configuration Examples**: Links to working configuration samples
- [ ] **Tool Documentation**: Links to official tool documentation

## Link Quality Standards

### ✅ Preferred Link Types

**Excellent (Use These):**
- Official vendor documentation (docs.servicenow.com, docs.openshift.com)
- Standards organizations (W3C, IETF, OWASP, NIST)
- Open source project documentation (GitHub official docs)
- Stable community resources (ServiceNow Community, Stack Overflow)

**Good (Use With Caution):**
- Well-established technical blogs (Martin Fowler, ThoughtWorks)
- Educational institutions (.edu domains)
- Established technology companies' technical content

**Avoid (Don't Use):**
- Personal blogs for critical technical references
- Links with version numbers in the URL
- Temporary or promotional URLs
- Links requiring authentication
- Social media posts as primary references

### ✅ ServiceNow-Specific Guidelines

**Preferred ServiceNow Links:**
```markdown
✅ https://community.servicenow.com/community?id=community_search&q=topic
✅ https://developer.servicenow.com/dev.do#!/learn/...
✅ https://docs.servicenow.com/bundle/vancouver-platform-administration/...
```

**Avoid ServiceNow Links:**
```markdown
❌ https://docs.servicenow.com/bundle/tokyo-... (version-specific)
❌ https://hi.service-now.com/... (requires authentication)
❌ Personal ServiceNow instance URLs
```

**ServiceNow Link Strategy:**
- Use Community links for discussions and examples
- Use Developer Program links for learning resources
- Use official docs for definitive technical references
- Provide multiple sources for critical ServiceNow concepts

### ✅ OpenShift and Red Hat Guidelines

**Preferred OpenShift Links:**
```markdown
✅ https://docs.openshift.com/container-platform/latest/...
✅ https://access.redhat.com/documentation/en-us/...
✅ https://kubernetes.io/docs/... (for K8s concepts)
```

**OpenShift Link Strategy:**
- Use "latest" version in URLs when possible
- Provide both OpenShift and upstream Kubernetes references
- Include Red Hat official documentation for enterprise features

## Common Issues and Solutions

### 🔴 Broken Link Patterns

**ServiceNow Documentation Timeouts:**
```markdown
# Problem
https://docs.servicenow.com/bundle/vancouver-platform-administration/page/...
# Solution
https://community.servicenow.com/community?id=community_search&q=business+rules
```

**Version-Specific URLs:**
```markdown
# Problem
https://docs.openshift.com/container-platform/4.12/...
# Solution  
https://docs.openshift.com/container-platform/latest/...
```

**Moved or Reorganized Content:**
```markdown
# Problem
https://www.thoughtworks.com/insights/blog/configuration-as-code
# Solution
https://martinfowler.com/bliki/InfrastructureAsCode.html
```

### 🟡 Warning Patterns

**Rate-Limited Sites:**
```markdown
# Problem
https://www.vaultproject.io/ (HTTP 429)
# Solution
https://developer.hashicorp.com/vault
```

**Slow-Loading Sites:**
- Increase timeout for known-slow but reliable sites
- Consider alternative sources for frequently accessed content
- Document known slow sites in validation configuration

## Validation Workflow

### 1. **Before Making Changes**
```bash
# Baseline validation
./docs/scripts/validate-links.sh --report-format json --output baseline.json
```

### 2. **After Making Changes**
```bash
# Full validation
./docs/scripts/validate-links.sh --fail-on-broken

# Review any new issues
git diff baseline.json current.json
```

### 3. **Before Committing**
```bash
# Final check
./docs/scripts/validate-links.sh --external-only --fail-on-broken

# Commit with validation confirmation
git commit -m "docs: update guide with validated links

- All external links validated
- Internal references verified
- Follows ADR-016 link standards"
```

### 4. **In Pull Requests**
- Include link validation results in PR description
- Address any broken links before requesting review
- Document any intentional exceptions with justification

## Emergency Procedures

### 🚨 Critical Broken Links
If validation reveals broken links in critical documentation:

1. **Immediate**: Comment out or replace with working alternative
2. **Short-term**: Find authoritative replacement source
3. **Long-term**: Consider archiving critical external content locally

### 🚨 Mass Link Failures
If many links fail (e.g., entire domain down):

1. **Verify**: Confirm it's not a temporary network issue
2. **Document**: Create GitHub issue tracking the problem
3. **Communicate**: Notify team of documentation impact
4. **Plan**: Develop strategy for replacing affected links

## Automation Integration

### CI/CD Pipeline Integration
```yaml
# .github/workflows/documentation.yml
- name: Validate Documentation Links
  run: |
    ./docs/scripts/validate-links.sh --fail-on-broken --report-format json
  continue-on-error: false
```

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-links
      name: Validate documentation links
      entry: ./docs/scripts/validate-links.sh
      language: script
      files: ^docs/.*\.md$
```

---

**Remember**: Link validation is about maintaining professional documentation standards and ensuring excellent user experience. When in doubt, prefer official sources and test thoroughly!
