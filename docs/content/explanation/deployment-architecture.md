# 🏗️ Deployment Architecture

**Understanding the ServiceNow-OpenShift integration deployment patterns and infrastructure design**

## 🎯 Architecture Overview

The ServiceNow-OpenShift integration follows a **four-tier architecture** with GitOps deployment patterns, designed for enterprise-scale automation and security.

```mermaid
graph TB
    subgraph "Tier 1: Orchestration"
        SN[ServiceNow ITSM]
        SC[Service Catalog]
        BR[Business Rules]
        WF[Workflow Engine]
    end
    
    subgraph "Tier 2: Automation Execution"
        AAP[Ansible Automation Platform]
        JT[Job Templates]
        EE[Execution Environment]
        CR[Credential Store]
    end
    
    subgraph "Tier 3: Identity Management"
        KC[Keycloak/RH-SSO]
        RL[Realms]
        CL[OAuth Clients]
        US[User Store]
    end
    
    subgraph "Tier 4: Container Platform"
        OCP[OpenShift Container Platform]
        NS[Namespaces/Projects]
        RB[RBAC/RoleBindings]
        NP[Network Policies]
    end
    
    SN --> AAP
    AAP --> KC
    AAP --> OCP
    KC --> OCP
    
    style SN fill:#e3f2fd
    style AAP fill:#fff3e0
    style KC fill:#f3e5f5
    style OCP fill:#e8f5e8
```

## 🚀 Deployment Patterns

### 1. GitOps-First Approach

**Infrastructure as Code** with declarative deployment:

```yaml
# kustomize/argocd/apps/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: servicenow-ocp-apps
spec:
  source:
    repoURL: https://github.com/tosin2013/servicenow-ocp-service.git
    path: kustomize/argocd/apps
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
```

**Key Benefits:**
- **Declarative**: All infrastructure defined in Git
- **Auditable**: Complete change history
- **Consistent**: Eliminates configuration drift
- **Secure**: Pull-based deployment model

### 2. Layered Kustomize Structure

**Environment-specific overlays** for different deployment targets:

```
kustomize/
├── ansible-automation-platform/
│   ├── base/                    # Base AAP configuration
│   └── overlays/
│       ├── development/         # Dev-specific settings
│       ├── staging/            # Staging configuration
│       └── production/         # Production hardening
├── rhsso/
│   ├── base/                   # Base Keycloak setup
│   └── overlays/
│       ├── crc/               # Local development
│       └── rhpds/             # RHPDS environment
└── external-secrets-operator/
    ├── base/                   # ESO base configuration
    └── overlays/
        └── vault-integration/ # Vault backend config
```

### 3. Operator-Based Deployment

**Kubernetes Operators** manage complex application lifecycles:

- **RH-SSO Operator**: Keycloak deployment and management
- **AAP Operator**: Ansible Automation Platform lifecycle
- **External Secrets Operator**: Secure credential management
- **OpenShift GitOps**: ArgoCD deployment and configuration

## 🔧 Component Deployment Flow

### Deployment Sequence Diagram

```mermaid
sequenceDiagram
    participant Admin as Administrator
    participant Git as Git Repository
    participant ArgoCD as ArgoCD
    participant OCP as OpenShift
    participant Ops as Operators

    Admin->>Git: Push infrastructure manifests
    Admin->>OCP: Deploy ArgoCD bootstrap
    OCP->>ArgoCD: ArgoCD starts
    ArgoCD->>Git: Sync app-of-apps
    ArgoCD->>OCP: Deploy operator subscriptions
    OCP->>Ops: Install operators
    Ops->>OCP: Create CRDs and controllers
    ArgoCD->>Git: Sync application instances
    ArgoCD->>OCP: Deploy AAP, Keycloak, ESO
    OCP->>Admin: Infrastructure ready

    Note over Admin,OCP: Total deployment time: 10-15 minutes
```

### Phase 1: Infrastructure Bootstrap

```mermaid
flowchart TD
    A[Administrator] --> B[Deploy ArgoCD Bootstrap]
    B --> C[ArgoCD Starts]
    C --> D[Deploy App-of-Apps]
    D --> E[Sync Operator Subscriptions]
    E --> F[Install Operators]
    F --> G{All Operators Ready?}
    G -->|No| H[Wait for Operators]
    H --> G
    G -->|Yes| I[Deploy Application Instances]
    I --> J[Infrastructure Complete]

    style A fill:#e3f2fd
    style J fill:#c8e6c9
    style G fill:#fff3e0
```

```bash
# 1. Deploy ArgoCD (OpenShift GitOps)
oc apply -k kustomize/argocd/bootstrap/

# 2. Deploy App-of-Apps pattern
oc apply -k kustomize/argocd/apps/

# 3. Wait for operator deployments
oc get pods -n sso
oc get pods -n aap
oc get pods -n external-secrets-operator
```

### Phase 2: Configuration Management

```bash
# 1. Configure base Keycloak realms and clients
./run_playbook.sh ansible/playbook.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass

# 2. Set up OpenShift OIDC integration
./run_playbook.sh ansible/openshift_oidc_playbook.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass

# 3. Configure AAP job templates and credentials
./run_playbook.sh ansible/configure_aap.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass
```

### Phase 3: ServiceNow Integration

```bash
# 1. Set up OAuth integration with Keycloak
./run_playbook.sh ansible/oauth_integration_playbook.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass

# 2. Configure ServiceNow business rules
./run_playbook.sh ansible/servicenow_business_rules.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass
```

## 🛡️ Security Architecture

### Security Flow Diagram

```mermaid
flowchart TB
    subgraph "Security Layers"
        TLS[TLS/SSL Termination]
        AUTH[Authentication Layer]
        AUTHZ[Authorization Layer]
        NET[Network Policies]
        VAULT[Credential Management]
    end

    subgraph "Authentication Flow"
        USER[User] --> SN[ServiceNow]
        SN --> KC[Keycloak OAuth2]
        KC --> OCP[OpenShift OIDC]
        OCP --> RBAC[RBAC Policies]
    end

    subgraph "Credential Flow"
        ESO[External Secrets Operator]
        VAULT_SRV[HashiCorp Vault]
        K8S_SEC[Kubernetes Secrets]

        ESO --> VAULT_SRV
        VAULT_SRV --> K8S_SEC
        K8S_SEC --> AAP[AAP Credentials]
        K8S_SEC --> KC
    end

    USER --> TLS
    TLS --> AUTH
    AUTH --> AUTHZ
    AUTHZ --> NET

    style TLS fill:#ffcdd2
    style AUTH fill:#f8bbd9
    style AUTHZ fill:#e1bee7
    style NET fill:#c5cae9
    style VAULT fill:#bbdefb
```

### 1. Credential Management

**External Secrets Operator** with HashiCorp Vault integration:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

### 2. Network Security

**Network Policies** for micro-segmentation:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: aap-controller-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: automation-controller
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: servicenow-integration
```

### 3. RBAC Integration

**OpenShift RBAC** with Keycloak group mapping:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: servicenow-project-admins
subjects:
- kind: Group
  name: servicenow-admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

## 📊 Deployment Environments

### Environment Comparison Diagram

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_SN[ServiceNow PDI]
        DEV_OCP[Single-node OpenShift]
        DEV_KC[Keycloak Basic]
        DEV_AAP[AAP Single Instance]

        DEV_SN -.->|Manual Trigger| DEV_AAP
        DEV_AAP --> DEV_KC
        DEV_AAP --> DEV_OCP
    end

    subgraph "Production Environment"
        PROD_SN[ServiceNow Enterprise<br/>Multi-Instance]
        PROD_OCP[Multi-node OpenShift<br/>HA Cluster]
        PROD_KC[Keycloak Cluster<br/>External DB]
        PROD_AAP[AAP HA<br/>3+ Replicas]

        PROD_SN -->|Business Rules| PROD_AAP
        PROD_AAP --> PROD_KC
        PROD_AAP --> PROD_OCP
    end

    style DEV_SN fill:#e3f2fd
    style PROD_SN fill:#c8e6c9
    style DEV_OCP fill:#fff3e0
    style PROD_OCP fill:#e8f5e8
```

### Development Environment

**Characteristics:**
- Single-node OpenShift (CRC) or RHPDS
- ServiceNow PDI instance
- Simplified authentication (htpasswd + Keycloak)
- Local vault for secrets
- Manual workflow execution due to PDI limitations

**Configuration:**
```yaml
# kustomize/rhsso/overlays/crc/kustomization.yaml
resources:
  - ../../base
  - oauth-rhsso-openid.yaml
  - client-secret.yaml

patches:
  - path: patch-issuer.yaml
    target:
      kind: OAuth
      name: cluster
```

### Production Environment

**Characteristics:**
- Multi-node OpenShift cluster
- Enterprise ServiceNow instance
- External identity providers
- Enterprise vault integration
- Monitoring and alerting

**Configuration:**
```yaml
# kustomize/rhsso/overlays/production/kustomization.yaml
resources:
  - ../../base
  - production-oauth.yaml
  - external-db-secret.yaml
  - monitoring-config.yaml

patches:
  - path: production-hardening.yaml
```

## 🔄 Continuous Deployment

### Complete GitOps Workflow

```mermaid
flowchart TD
    DEV[Developer] --> PR[Create Pull Request]
    PR --> REVIEW[Code Review]
    REVIEW --> MERGE[Merge to Main]
    MERGE --> WEBHOOK[Git Webhook]
    WEBHOOK --> ARGOCD[ArgoCD Sync]
    ARGOCD --> VALIDATE[Validate Manifests]
    VALIDATE --> APPLY[Apply to Cluster]
    APPLY --> HEALTH[Health Check]
    HEALTH --> NOTIFY[Notification]

    HEALTH -->|Failed| ROLLBACK[Automatic Rollback]
    ROLLBACK --> ALERT[Alert Team]

    style DEV fill:#e3f2fd
    style MERGE fill:#c8e6c9
    style HEALTH fill:#fff3e0
    style ROLLBACK fill:#ffcdd2
```

### GitOps Sequence Diagram

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant ArgoCD as ArgoCD
    participant OCP as OpenShift
    participant Monitor as Monitoring

    Dev->>Git: Push configuration changes
    Git->>ArgoCD: Webhook notification
    ArgoCD->>Git: Pull latest changes
    ArgoCD->>ArgoCD: Validate manifests
    ArgoCD->>OCP: Apply manifests
    OCP-->>ArgoCD: Deployment status
    ArgoCD->>Monitor: Update metrics
    Monitor->>Dev: Notification (Slack/Email)

    Note over Dev,Monitor: Continuous feedback loop
```

### Deployment Validation

**Automated health checks** ensure deployment success:

```bash
# Health check script
./scripts/validate-deployment.sh --environment production

# Checks performed:
# ✅ All pods running
# ✅ Services accessible
# ✅ OAuth integration working
# ✅ AAP job templates configured
# ✅ ServiceNow connectivity
```

## 📈 Scaling Considerations

### Scaling Architecture Diagram

```mermaid
graph TB
    subgraph "Horizontal Scaling"
        AAP1[AAP Controller 1]
        AAP2[AAP Controller 2]
        AAP3[AAP Controller 3]
        LB_AAP[Load Balancer]

        KC1[Keycloak 1]
        KC2[Keycloak 2]
        KC3[Keycloak 3]
        LB_KC[Load Balancer]

        LB_AAP --> AAP1
        LB_AAP --> AAP2
        LB_AAP --> AAP3

        LB_KC --> KC1
        LB_KC --> KC2
        LB_KC --> KC3
    end

    subgraph "Vertical Scaling"
        CPU[CPU Scaling<br/>2-8 cores]
        MEM[Memory Scaling<br/>4-16 GB]
        STORAGE[Storage Scaling<br/>100GB-1TB]
    end

    subgraph "Database Scaling"
        DB_PRIMARY[Primary DB]
        DB_REPLICA1[Read Replica 1]
        DB_REPLICA2[Read Replica 2]

        DB_PRIMARY --> DB_REPLICA1
        DB_PRIMARY --> DB_REPLICA2
    end

    AAP1 --> DB_PRIMARY
    KC1 --> DB_PRIMARY

    style LB_AAP fill:#e3f2fd
    style LB_KC fill:#f3e5f5
    style DB_PRIMARY fill:#c8e6c9
```

### Horizontal Scaling

- **AAP Controller**: Multiple replicas with load balancing
- **Keycloak**: Clustered deployment with external database
- **ServiceNow**: Multiple instances with load balancer

### Vertical Scaling

- **Resource Quotas**: Per-namespace limits
- **Node Affinity**: Workload placement optimization
- **Storage Classes**: Performance-optimized storage

## 🔍 Monitoring and Observability

### Built-in OpenShift Monitoring

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **AlertManager**: Alert routing and notification

### Custom Metrics

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: aap-controller-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: automation-controller
  endpoints:
  - port: metrics
    interval: 30s
```

## 🎯 Best Practices

### 1. Infrastructure as Code
- All configurations in Git
- Environment-specific overlays
- Automated testing of manifests

### 2. Security First
- Least privilege access
- Network segmentation
- Credential rotation

### 3. Operational Excellence
- Comprehensive monitoring
- Automated backups
- Disaster recovery procedures

---

**Next Steps**: Review the [Getting Started Guide](../GETTING_STARTED.md) for step-by-step deployment instructions.
