# ServiceNow-OpenShift Integration

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.x+-red.svg)](https://www.openshift.com/)
[![ServiceNow](https://img.shields.io/badge/ServiceNow-ITSM-green.svg)](https://www.servicenow.com/)
[![Ansible](https://img.shields.io/badge/Ansible-AAP-orange.svg)](https://www.ansible.com/)

> **Enterprise-grade ServiceNow to OpenShift project provisioning automation** with Ansible Automation Platform, Keycloak SSO, and GitOps deployment patterns.

## 🎯 What This Does

This project provides a **production-ready, community-adoptable solution** for automating OpenShift project provisioning through ServiceNow ITSM workflows:

- 🏗️ **Four-Tier Architecture** - ServiceNow → AAP → Keycloak → OpenShift
- 🔐 **Enterprise SSO** - **Keycloak/RH-SSO** integration with OpenShift OIDC + ServiceNow OAuth2
- 🤖 **Full Automation** - Business Rules trigger Ansible job templates
- 📋 **Service Catalog** - Professional ServiceNow catalog items
- 🔄 **GitOps Ready** - ArgoCD and Kustomize deployment patterns
- 🛡️ **Security First** - Vault-based credential management
- 📚 **Comprehensive Docs** - 15 ADRs + complete implementation guides

## 🚀 Quick Start

### Prerequisites

- **OpenShift 4.x+** cluster with admin access
- **ServiceNow** instance (PDI or enterprise)
- **Ansible Automation Platform** (or AWX)
- **Git** and **oc** CLI tools

### 1. Clone and Setup

```bash
git clone https://github.com/tosin2013/servicenow-ocp-service.git
cd servicenow-ocp-service

# Set up vault password file
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
```

### 2. Deploy Infrastructure (GitOps)

```bash
# Deploy core components via ArgoCD
oc apply -k kustomize/argocd/apps/

# Wait for deployments to be ready
oc get pods -n sso
oc get pods -n aap
oc get pods -n external-secrets-operator
```

### 3. Configure Integration

```bash
# Run the complete setup workflow
./run_playbook.sh ansible/preflight_checks.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
./run_playbook.sh ansible/playbook.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
./run_playbook.sh ansible/configure_aap.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

### 4. Test End-to-End

```bash
# Run the simplified workflow test
cd user-workflows/advanced/
./start-simplified-workflow.sh my-test-project development full
```

## 📖 Documentation

### 🎓 **Getting Started**
- **[Getting Started Guide](docs/GETTING_STARTED.md)** - Complete setup walkthrough
- **[Keycloak Integration Guide](docs/KEYCLOAK_INTEGRATION_GUIDE.md)** - 🔐 **Identity & SSO Setup**
- **[User Experience Guide](docs/user-experience-guide.md)** - End-user journey
- **[End-to-End Test Guide](docs/end-to-end-test-guide.md)** - Validation workflows

### 🏗️ **Architecture**
- **[ADRs](docs/adrs/)** - 15 architectural decision records
- **[Architecture Overview](docs/explanation/architecture-overview.md)** - System design
- **[Four-Tier Architecture](docs/adrs/001-three-tier-orchestration-architecture.md)** - Core design

### 🔧 **Implementation**
- **[Business Rules Setup](docs/BUSINESS_RULE_LOGIC_DOCUMENTATION.md)** - ServiceNow automation
- **[AAP Integration](docs/AAP_TOKEN_SETUP_GUIDE.md)** - Ansible Automation Platform
- **[Execution Environment](execution-environment/)** - Custom container builds

### 🧪 **Testing & Validation**
- **[Validation Summary](VALIDATION_SUMMARY.md)** - Test results
- **[User Workflows](user-workflows/)** - Step-by-step automation

## 🏗️ Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ ServiceNow  │───▶│    AAP      │───▶│  Keycloak   │───▶│ OpenShift   │
│(Orchestrate)│    │ (Execute)   │    │ (Identity)  │    │ (Resources) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Key Components:**
- **ServiceNow**: Service catalog, business rules, workflow orchestration
- **Ansible Automation Platform**: Job templates, execution environments
- **Keycloak/RH-SSO**: Identity provider, OAuth2/OIDC integration
- **OpenShift**: Project provisioning, RBAC, resource management

## 🎯 Use Cases

### **Enterprise IT Service Management**
- Automated OpenShift project provisioning via ServiceNow catalog
- Self-service developer environments with approval workflows
- Integrated identity management and access control

### **DevOps Platform Automation**
- GitOps-based infrastructure deployment
- Standardized project templates and resource quotas
- Comprehensive audit trails and compliance reporting

### **Multi-Tenant Container Platform**
- Secure project isolation with network policies
- Role-based access control integration
- Automated user onboarding and offboarding

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup and guidelines
- Code standards and testing requirements
- How to submit issues and pull requests

### **Development Workflow**
1. Fork the repository
2. Create a feature branch
3. Test your changes with the validation workflows
4. Submit a pull request with clear description

## 📋 Project Status

- ✅ **Core Architecture**: Four-tier integration complete
- ✅ **ServiceNow Integration**: Business rules and catalog items
- ✅ **AAP Integration**: Job templates and execution environments
- ✅ **Security**: Vault-based credential management
- ✅ **Testing**: End-to-end validation workflows
- ✅ **Documentation**: Comprehensive ADRs and guides

## 🛡️ Security

- All credentials managed via Ansible Vault
- OAuth2/OIDC integration between all components
- Network policies and RBAC enforcement
- Regular security scanning and updates

Report security issues to: [SECURITY.md](SECURITY.md)

## 📄 License

Apache License 2.0 - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **Red Hat Community** - Architecture patterns and best practices
- **ServiceNow Developers** - ITSM integration expertise
- **OpenShift Community** - Container platform guidance
- **Ansible Community** - Automation and execution environment patterns

---

**Ready to automate your OpenShift provisioning?** Start with the [Getting Started Guide](docs/GETTING_STARTED.md)!
