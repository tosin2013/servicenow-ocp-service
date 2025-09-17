# ADR-012: Ansible Automation Platform Kustomize-based Deployment

**Status:** Accepted

**Date:** 2025-09-09

## Context

The implementation of ADR-010 (Ansible Automation Platform Integration) and ADR-011 (Custom Execution Environment) requires a standardized, GitOps-aligned deployment method for AAP on OpenShift. The AAP deployment must integrate with the existing kustomize structure established in ADR-004 and provide the automation execution tier for the ServiceNow-OpenShift integration.

The project now includes a complete kustomize structure at `kustomize/ansible-automation-platform/` with operator and instance deployment configurations, supporting the four-tier architecture defined in ADR-010.

## Decision

Deploy Ansible Automation Platform using kustomize overlays with an operator-based installation pattern. The deployment structure includes:

### Deployment Components

1. **AAP Operator Installation**: Via subscription in the 'aap' namespace with configurable channels
2. **AnsibleAutomationPlatform Instance**: Custom resource with controller components enabled
3. **AutomationHub Instance**: Separate hub deployment for content management and private collections
4. **Layered Kustomize Structure**: Base configurations and environment-specific overlays
5. **GitOps Integration**: Automated deployment and lifecycle management via ArgoCD

### Directory Structure

```
kustomize/ansible-automation-platform/
├── operator/              # AAP Operator deployment
│   ├── base/              # Base operator subscription
│   └── overlays/          # Channel-specific overlays (stable-2.4, stable-2.5, etc.)
├── instance/              # AAP Instance deployment
│   ├── base/              # Base AutomationController configuration
│   └── overlays/          # Environment-specific configurations (dev, staging, prod)
├── hub-instance/          # AAP Hub Instance deployment
│   ├── base/              # Base AutomationHub configuration
│   └── overlays/          # Environment-specific hub configurations
└── README.md              # Deployment documentation
```

### Hub-Instance Separation

The `hub-instance/` directory provides separate deployment configuration for AutomationHub, enabling:
- **Content Management**: Centralized location for custom Ansible collections and execution environments
- **Private Collections**: Secure hosting of organization-specific automation content
- **Separation of Concerns**: Hub can be deployed independently from the controller
- **Resource Optimization**: Different scaling and resource requirements for hub vs controller

This approach provides:
```

### Key Configuration Elements

- **Namespace**: `aap` with cluster monitoring enabled
- **Components**: Controller enabled, Hub enabled, EDA disabled, Lightspeed disabled
- **Storage**: Configurable storage class for hub file storage (100Gi default)
- **Route**: Edge TLS termination for secure access
- **Redis**: Standalone mode for simplified deployment

## Rationale

This approach provides:
- **GitOps Alignment**: Consistent with ADR-004's declarative deployment principles
- **Operator Benefits**: Automated lifecycle management and platform integration
- **Environment Flexibility**: Multiple overlays support dev/test/prod environments
- **Integration Ready**: Supports the automation execution tier defined in ADR-010

## Consequences

### Positive Consequences

- **Standardized Deployment**: Consistent, repeatable AAP deployments across environments
- **Reduced Operational Overhead**: Operator-managed lifecycle reduces manual intervention
- **GitOps Integration**: Seamless integration with existing ArgoCD deployment pipeline
- **Environment Management**: Clean separation of environment-specific configurations
- **Scalability**: Supports multiple AAP versions and deployment scenarios

### Negative Consequences

- **Complexity**: Additional kustomize structure increases deployment complexity
- **Dependencies**: Reliance on RedHat operators and subscription management
- **Resource Requirements**: AAP controller and hub components require significant cluster resources
- **Operator Coupling**: Deployment lifecycle tied to operator availability and compatibility

### Risk Mitigation

- **Resource Planning**: Define clear resource requirements and limits
- **Backup Strategy**: Implement backup procedures for AAP configuration and data
- **Monitoring**: Integrate with observability strategy (ADR-008)
- **Documentation**: Maintain clear operational runbooks

## Implementation Considerations

### Prerequisites
- OpenShift 4.12+ with sufficient resources
- RedHat operator subscription access
- Configured storage class for persistent volumes

### Deployment Sequence
1. Deploy AAP operator via kustomize overlay
2. Verify operator installation and readiness
3. Deploy AAP instance via kustomize overlay
4. Configure console links and access
5. Integration with ArgoCD application sync

## References

- **ADR-004**: GitOps-based Deployment with ArgoCD and Kustomize
- **ADR-010**: Ansible Automation Platform Integration
- **ADR-011**: Custom Execution Environment for AAP
- **ADR-008**: Observability Strategy (for monitoring integration)
