# ServiceNow-OpenShift Integration Documentation

This directory contains comprehensive documentation for the ServiceNow-OpenShift integration system, including architectural decision records (ADRs), getting started guides, and operational documentation.

## Quick Start

**New to the system?** Start with the [Getting Started Guide](getting-started.md) for step-by-step instructions on deploying and using the ServiceNow-OpenShift integration.

## Documentation Structure

```
docs/
├── getting-started.md           # 🚀 Quick start guide for new users
├── adrs/                        # 📋 Architectural Decision Records
│   ├── 001-three-tier-orchestration-architecture.md
│   ├── 002-decoupled-api-driven-integration.md
│   ├── 003-centralized-configuration-with-connection-credential-aliases.md
│   ├── 004-gitops-based-deployment-with-argocd-and-kustomize.md
│   ├── 005-keycloak-deployment-on-openshift-via-operator.md
│   ├── 006-servicenow-implementation-with-flow-designer-and-integrationhub.md
│   ├── 007-secret-management-with-external-secrets-operator.md
│   ├── 008-observability-strategy-using-openshift-built-in-monitoring.md
│   ├── 009-hybrid-gitops-and-ansible-configuration.md
│   ├── 010-ansible-automation-platform-integration.md
│   ├── 011-custom-execution-environment-for-aap.md
│   └── 012-ansible-automation-platform-kustomize-deployment.md
└── research/                    # 📚 Research and analysis documents
```

## System Overview

The ServiceNow-OpenShift integration implements a **four-tier architecture** that automates user provisioning and project creation:

### Architecture Tiers

1. **ServiceNow (Orchestration Tier)**
   - Service Catalog for user requests
   - Flow Designer for workflow automation
   - IntegrationHub for API integrations

2. **Ansible Automation Platform (Automation Execution Tier)**
   - Job Templates for infrastructure automation
   - Custom Execution Environment with required dependencies
   - Centralized credential management

3. **Keycloak/RH-SSO (Identity Tier)**
   - User identity management
   - OIDC integration with OpenShift
   - Centralized authentication

4. **OpenShift (Resource Tier)**
   - Project/namespace provisioning
   - RBAC and resource quota management
   - Container platform resources

### Key Capabilities

- **Automated User Provisioning**: Create users in Keycloak with OpenShift access
- **Project Lifecycle Management**: Automated project creation with custom configurations
- **Self-Service Portal**: ServiceNow service catalog for end-user requests
- **GitOps Deployment**: Declarative infrastructure management with ArgoCD
- **Secure Integration**: API-driven with centralized credential management

## Architectural Decision Records (ADRs)

Our ADRs document key architectural decisions and their rationale. They are organized by implementation sequence:

### Foundation Layer (ADRs 001-003)
- **[ADR-001](adrs/001-three-tier-orchestration-architecture.md)**: Establishes the core three-tier architecture
- **[ADR-002](adrs/002-decoupled-api-driven-integration.md)**: Defines API-driven integration approach
- **[ADR-003](adrs/003-centralized-configuration-with-connection-credential-aliases.md)**: Centralizes credential management

### Deployment and Infrastructure (ADRs 004-005)
- **[ADR-004](adrs/004-gitops-based-deployment-with-argocd-and-kustomize.md)**: Establishes GitOps deployment strategy
- **[ADR-005](adrs/005-keycloak-deployment-on-openshift-via-operator.md)**: Defines identity platform deployment

### Integration Layer (ADRs 006-007)
- **[ADR-006](adrs/006-servicenow-implementation-with-flow-designer-and-integrationhub.md)**: ServiceNow workflow implementation
- **[ADR-007](adrs/007-secret-management-with-external-secrets-operator.md)**: Secure secret management

### Operations and Monitoring (ADRs 008-009)
- **[ADR-008](adrs/008-observability-strategy-using-openshift-built-in-monitoring.md)**: Monitoring and observability
- **[ADR-009](adrs/009-hybrid-gitops-and-ansible-configuration.md)**: Hybrid deployment approach

### Automation Platform (ADRs 010-012)
- **[ADR-010](adrs/010-ansible-automation-platform-integration.md)**: Introduces AAP as automation tier
- **[ADR-011](adrs/011-custom-execution-environment-for-aap.md)**: Custom execution environment for dependencies
- **[ADR-012](adrs/012-ansible-automation-platform-kustomize-deployment.md)**: AAP deployment via kustomize

## Implementation Status

### ✅ Completed Components
- ADR documentation framework
- Kustomize deployment structure for AAP
- GitOps foundation with ArgoCD
- Ansible automation playbooks
- Basic monitoring and observability

### 🚧 In Progress
- ServiceNow Flow Designer workflows
- AAP job template configuration
- End-to-end integration testing
- Production deployment procedures

### 📋 Planned
- Advanced monitoring and alerting
- Disaster recovery procedures
- Performance optimization
- Additional self-service capabilities

## Getting Started Paths

### For New Users
1. Read the [Getting Started Guide](getting-started.md)
2. Review the [Architecture Overview](#system-overview)
3. Follow the deployment instructions
4. Test with a sample project request

### For Developers
1. Study ADRs 001-003 for architecture foundation
2. Review ADRs 004-007 for deployment and integration patterns
3. Examine the kustomize structure in `/kustomize`
4. Review Ansible playbooks in `/ansible`

### For Operations Teams
1. Focus on ADRs 008-012 for operational concerns
2. Review monitoring and observability setup
3. Study the AAP deployment and configuration
4. Prepare operational runbooks

### For Architects
1. Review all ADRs for comprehensive understanding
2. Examine decision rationale and trade-offs
3. Consider future architectural enhancements
4. Plan integration with existing systems

## Key Technologies

| Technology | Purpose | ADR Reference |
|------------|---------|---------------|
| **ServiceNow** | Orchestration and workflow | ADR-001, ADR-006 |
| **Ansible Automation Platform** | Automation execution | ADR-010, ADR-011, ADR-012 |
| **Keycloak/RH-SSO** | Identity and access management | ADR-001, ADR-005 |
| **OpenShift** | Container platform | ADR-001, ADR-004 |
| **ArgoCD** | GitOps deployment | ADR-004 |
| **Kustomize** | Configuration management | ADR-004, ADR-012 |
| **External Secrets Operator** | Secret management | ADR-007 |

## Contributing

When making architectural changes:

1. **Update relevant ADRs** with implementation details
2. **Create new ADRs** for significant decisions
3. **Update this documentation** to reflect changes
4. **Test end-to-end workflows** before finalizing
5. **Review with stakeholders** for approval

## Support and Troubleshooting

- **Documentation Issues**: Create an issue in the repository
- **Deployment Problems**: Check the troubleshooting section in the getting started guide
- **Architecture Questions**: Review relevant ADRs or contact the architecture team

## Related Resources

- **Project Repository**: Core implementation and configuration files
- **Ansible Playbooks**: `/ansible` directory for automation logic
- **Kustomize Configurations**: `/kustomize` directory for deployment manifests
- **ServiceNow Workflows**: Integration Hub spokes and Flow Designer workflows

---

**Last Updated**: September 9, 2025  
**Version**: 1.0  
**Status**: Active Development
