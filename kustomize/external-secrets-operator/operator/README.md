# External Secrets Operator

This directory contains the Kustomize manifests for deploying the External Secrets Operator via OLM (Operator Lifecycle Manager).

## Structure

```
operator/
├── base/
│   ├── install.yaml        # Namespace, OperatorGroup, and Subscription
│   └── kustomization.yaml
└── overlays/
    └── stable/             # Stable channel overlay
        ├── patch-channel.yaml
        └── kustomization.yaml
```

## Usage

### Deploy via Kustomize

```bash
# Deploy the External Secrets Operator
oc apply -k kustomize/external-secrets-operator/operator/overlays/stable
```

### Deploy via ArgoCD

The operator is automatically deployed via the ArgoCD App-of-Apps pattern:

```bash
# Deploy the app-of-apps which includes this operator
oc apply -f kustomize/argocd/apps/app-of-apps.yaml
```

## Operator Configuration

The operator is configured to:
- **Source**: `community-operators` catalog
- **Channel**: `stable`
- **Install Mode**: Automatic approval
- **Target Namespaces**: All namespaces (empty targetNamespaces array)

This allows the External Secrets Operator to manage ExternalSecret resources across all namespaces in the cluster.

## Post-Installation

After the operator is installed, you can:

1. Create SecretStore resources
2. Deploy ExternalSecret resources that reference the SecretStores
3. Configure the operator via the OperatorConfig CRD

See the `manifests/` directory for example configurations.


