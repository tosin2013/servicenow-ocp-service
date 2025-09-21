# Contributing to ServiceNow-OpenShift Integration

Thank you for your interest in contributing to this enterprise ServiceNow-OpenShift integration project! This guide will help you get started with development and contributions.

## 🎯 Project Overview

This project provides a production-ready, four-tier architecture for automating OpenShift project provisioning through ServiceNow ITSM workflows. We follow Red Hat's architectural best practices and maintain comprehensive documentation through ADRs (Architectural Decision Records).

## 🚀 Getting Started

### Prerequisites

- **OpenShift 4.x+** cluster access
- **ServiceNow** instance (PDI for development)
- **Ansible** 2.9+ with `servicenow.itsm` collection
- **Git** and basic shell scripting knowledge
- **Python 3.8+** for development tools

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/servicenow-ocp-service.git
   cd servicenow-ocp-service
   ```

2. **Set Up Vault**
   ```bash
   # Create vault password file
   echo "your-development-vault-password" > .vault_pass
   chmod 600 .vault_pass
   
   # Edit vault variables
   ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
   ```

3. **Test Your Setup**
   ```bash
   # Run preflight checks
   ./run_playbook.sh ansible/preflight_checks.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
   
   # Test end-to-end workflow
   cd user-workflows/advanced/
   ./start-simplified-workflow.sh test-project development check-first
   ```

## 📋 Development Guidelines

### Code Standards

- **Ansible Playbooks**: Follow [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- **Shell Scripts**: Use `set -euo pipefail` and proper error handling
- **Documentation**: Update ADRs for architectural changes
- **Security**: Never commit secrets; use Ansible Vault

### Testing Requirements

All contributions must include:

1. **Functional Testing**
   ```bash
   # Test your changes with the validation workflow
   ./run_playbook.sh ansible/idempotent_end_to_end_test.yml --tags "setup,catalog" -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
   ```

2. **Documentation Updates**
   - Update relevant ADRs if architectural changes are made
   - Update user guides if workflow changes are made
   - Test documentation with MkDocs: `cd docs && mkdocs serve`

3. **Link Validation** (Required for documentation changes)
   ```bash
   # Validate all documentation links before submitting
   ./docs/scripts/validate-links.sh

   # For CI/CD integration, fail on broken links
   ./docs/scripts/validate-links.sh --fail-on-broken

   # Quick external link check only
   ./docs/scripts/validate-links.sh --external-only --timeout 10
   ```

   **Link Quality Standards:**
   - ✅ Use official documentation when available
   - ✅ Prefer stable URLs over version-specific links
   - ✅ Provide fallback references for critical concepts
   - ✅ Test all new external links before submission
   - ❌ Avoid blog posts for critical technical references
   - ❌ Don't use links with temporary or promotional URLs

4. **Security Validation**
   ```bash
   # Ensure no secrets in code
   grep -r "password\|secret\|token" --exclude-dir=.git --exclude="*.md" . | grep -v vault
   ```

### Architectural Decision Records (ADRs)

For significant architectural changes, create or update ADRs:

1. **Review Existing ADRs**: Check `docs/adrs/` for related decisions
2. **Follow ADR Template**: Use the template in `docs/adrs/README.md`
3. **Get Review**: Discuss architectural changes in issues first

## 🔄 Contribution Workflow

### 1. Issue First
- Create an issue describing the problem or enhancement
- Discuss the approach with maintainers
- Get consensus before starting significant work

### 2. Branch Strategy
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

### 3. Development Process
- Make small, focused commits
- Write clear commit messages
- Test thoroughly with validation workflows
- Update documentation as needed

### 4. Pull Request
- Create PR with clear title and description
- Reference related issues
- Include testing evidence
- Request review from maintainers

## 🧪 Testing Your Changes

### End-to-End Validation
```bash
# Full workflow test
cd user-workflows/advanced/
./start-simplified-workflow.sh contrib-test-$(date +%s) development full

# Specific component tests
./run_playbook.sh ansible/test_servicenow_connection.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

### Documentation Testing
```bash
# Test MkDocs build
cd docs
pip install -r requirements.txt
mkdocs build
mkdocs serve
```

## 📚 Key Areas for Contribution

### 🔧 **Technical Enhancements**
- Additional ServiceNow catalog items
- Enhanced error handling and logging
- Performance optimizations
- Security improvements

### 📖 **Documentation**
- User experience improvements
- Troubleshooting guides
- Video tutorials
- Translation to other languages

### 🧪 **Testing & Validation**
- Additional test scenarios
- Automated testing improvements
- Integration with CI/CD pipelines
- Performance testing

### 🏗️ **Architecture & Design**
- Support for additional identity providers
- Multi-cluster support
- Cloud provider integrations
- Disaster recovery patterns

## 🛡️ Security Guidelines

- **Never commit secrets**: Use Ansible Vault for all sensitive data
- **Follow least privilege**: Minimize permissions in RBAC configurations
- **Validate inputs**: Sanitize all user inputs in scripts and playbooks
- **Regular updates**: Keep dependencies and base images updated

## 📞 Getting Help

- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check `docs/` for comprehensive guides
- **ADRs**: Review architectural decisions in `docs/adrs/`

## 🎯 Code Review Process

### What We Look For
- **Functionality**: Does it work as intended?
- **Security**: Are credentials properly managed?
- **Documentation**: Are changes documented?
- **Testing**: Is there evidence of testing?
- **Architecture**: Does it align with existing ADRs?

### Review Timeline
- Initial review within 48 hours
- Follow-up reviews within 24 hours
- Merge after approval from 2 maintainers

## 🏆 Recognition

Contributors will be recognized in:
- Project README acknowledgments
- Release notes for significant contributions
- GitHub contributor graphs and statistics

## 📄 License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

**Ready to contribute?** Start by creating an issue to discuss your ideas!
