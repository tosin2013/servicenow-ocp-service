# Implementation Guide

This comprehensive implementation guide outlines the complete steps to deploy and configure the ServiceNow-OpenShift integration solution. The process involves a declarative setup via GitOps, followed by a series of imperative configuration steps using Ansible.

> **New to the system?** Start with the [Getting Started Tutorial](tutorials/getting-started.md) for a learning-oriented overview, then return here for detailed implementation steps.

## 1. Prerequisites

Ensure you are logged into your OpenShift cluster with administrative privileges.

```bash
oc login --token=<your-token> --server=<your-server-url>
```

## 2. Deploy Infrastructure via GitOps

The core components (Ansible Automation Platform, RH-SSO, External Secrets Operator) are deployed using a GitOps approach with ArgoCD. The root application `servicenow-ocp-apps` in `kustomize/argocd/apps/app-of-apps.yaml` will manage the deployment of all necessary operators and instances.

**Wait for the deployments in the `sso`, `aap`, and `external-secrets-operator` namespaces to become healthy before proceeding.**

## 3. Configure AAP API Token

### 3.1 AAP API Token Setup

**CRITICAL**: Now that AAP is deployed, you must create an API token for ServiceNow integration. This token is required for all subsequent integration steps. Follow the detailed guide:

📋 **[AAP Token Setup Guide](how-to/aap-token-setup.md)** - Step-by-step token creation and vault configuration

This token is required for:
- ServiceNow Business Rules to trigger AAP job templates
- Pre-flight checks to validate AAP connectivity
- All ServiceNow → AAP integration workflows

## 4. Run Pre-flight Checks

Before applying any configuration, run the pre-flight check playbook to verify connectivity and authentication to all three tiers: OpenShift, Keycloak (RH-SSO), and ServiceNow. This will also validate your AAP token configuration.

```bash
./run_playbook.sh ../ansible/preflight_checks.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

## 5. Prerequisite: Configure Base RH-SSO Realms and Clients

This is the first and most critical configuration playbook. It sets up the foundational realms and clients in RH-SSO (Keycloak) that are required by both OpenShift and ServiceNow.

```bash
./run_playbook.sh ../ansible/playbook.yml -e @../ansible/group_vars/all/vault.yml  --vault-password-file .vault_pass -m stdout
```

## 6. Configure OpenShift OIDC with Keycloak (RH-SSO)

This playbook configures OpenShift to use the Keycloak realms you just created as its OIDC identity provider.

```bash
./run_playbook.sh ../ansible/openshift_oidc_playbook.yml -e @../ansible/group_vars/all/vault.yml  --vault-password-file .vault_pass -m stdout
```

## 7. Configure ServiceNow and Keycloak OAuth Integration

This playbook sets up the OAuth relationship between ServiceNow and Keycloak, allowing them to securely communicate.

```bash
./run_playbook.sh ../ansible/oauth_integration_playbook.yml -e @../ansible/group_vars/all/vault.yml  --vault-password-file .vault_pass -m stdout
```

## 8. Configure Ansible Automation Platform (AAP)

This playbook configures AAP with the necessary projects, credentials, and job templates for the ServiceNow integration. The AAP API token configured in Section 3 will be used for authentication.

```bash
./run_playbook.sh ../ansible/configure_aap.yml -e @../ansible/group_vars/all/vault.yml  --vault-password-file .vault_pass -m stdout
```

## 9. ServiceNow Integration Phase 1: Business Rules Setup

### 9.1 Business Rules Implementation

**IMPORTANT**: This project uses **Business Rules** for ServiceNow automation, not Flow Designer. This decision was made after comprehensive research (see [ADR-014](adrs/014-business-rules-over-flow-designer.md)).

**Why Business Rules?**
- Direct state change triggers (no additional layers needed)
- Better alignment with GitOps principles (code-based, version controlled)
- Superior error handling and debugging capabilities
- No PDI environment limitations

### 9.2 Configure Business Rules for AAP Integration

Set up the ServiceNow Business Rules for AAP integration:

```bash
./run_playbook.sh ../ansible/servicenow_business_rules_setup.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

This playbook will:
- Test ServiceNow API connectivity
- Configure Business Rules for catalog request automation
- Set up AAP job template triggering
- Provide validation and testing instructions

### 9.3 Explore ServiceNow ITSM Collection Modules

First, explore the available ServiceNow modules in the execution environment:

```bash
# List all ServiceNow ITSM modules
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc servicenow.itsm -l

# Get detailed documentation for specific modules
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc servicenow.itsm.service_catalog
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc servicenow.itsm.catalog_request
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc servicenow.itsm.configuration_item
```

### 9.4 Business Rules Configuration and Testing

After running the setup playbook, validate the Business Rules configuration:

1. **Verify Business Rules**:
   - Navigate to: **System Definition > Business Rules**
   - Look for: "OpenShift Project AAP Trigger"
   - Ensure it's **Active** and configured for the `sc_req_item` table

2. **Test Business Rules Logic**:
   ```bash
   # Test the Business Rules logic locally
   node test_business_rule_logic.js

   # Test the complete workflow (PDI workaround)
   ./user-workflows/advanced/start-simplified-workflow.sh test-project development full
   ```

3. **Validate End-to-End Integration**:
   ```bash
   # Run comprehensive end-to-end test
   ./run_playbook.sh ../ansible/idempotent_end_to_end_test.yml --vault-password-file ../.vault_pass
   ```

   See the [Business Rule Logic Documentation](how-to/business-rule-logic.md) for detailed implementation details.

### 9.5 Create ServiceNow Catalog Items

Create professional catalog items for OpenShift services using the servicenow.itsm collection:

```bash
./run_playbook.sh ../ansible/servicenow_catalog_setup.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

**Note**: Business Rules provide direct, efficient automation for catalog request processing. They trigger automatically when requests change to "In Process" state and call AAP job templates via REST API.

## 10. ServiceNow Integration Phase 2: CMDB and Incident Management

### 10.1 Set Up Configuration Management Database (CMDB)

Configure ServiceNow CMDB to track OpenShift resources as configuration items:

```bash
./run_playbook.sh ../ansible/servicenow_cmdb_setup.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

### 10.2 Configure Incident Management Integration

Set up automated incident creation for failed provisioning attempts:

```bash
./run_playbook.sh ../ansible/servicenow_incident_setup.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

## 11. ServiceNow Integration Phase 3: Testing and Validation

### 11.1 Test Individual ServiceNow Modules

Test each ServiceNow integration component individually:

```bash
# Test catalog item creation
./run_playbook.sh ../ansible/test_servicenow_catalog.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout

# Test business rule integration
./run_playbook.sh ../ansible/test_servicenow_business_rules.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout

# Test CMDB integration
./run_playbook.sh ../ansible/test_servicenow_cmdb.yml -e @../ansible//group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

### 11.2 End-to-End Integration Testing

Test the complete ServiceNow → AAP → OpenShift → Keycloak workflow:

```bash
./run_playbook.sh ../ansible/test_end_to_end_integration.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

For comprehensive testing procedures and troubleshooting, see the **[End-to-End Test Guide](how-to/end-to-end-testing.md)** which provides detailed testing scenarios and validation steps.

### 11.3 Manual AAP Job Template Testing

Test the AAP job template directly to ensure it works with ServiceNow variables:

```bash
# Test with sample ServiceNow catalog request data
curl -s -k -u "admin:${AAP_PASSWORD}" -X POST \
  "https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/api/v2/job_templates/9/launch/" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "project_name": "test-servicenow-integration",
      "display_name": "Test ServiceNow Integration",
      "requestor": "testuser",
      "servicenow_request_number": "REQ0000028",
      "requestor_first_name": "Test",
      "requestor_last_name": "User",
      "requestor_role": "Developer",
      "temp_password": "TestPass123!"
    }
  }'
```

## 12. Production Deployment and Monitoring

### 12.1 Deploy to Production ServiceNow Instance

Deploy the catalog items and business rules to the production ServiceNow instance:

```bash
./run_playbook.sh ../ansible/servicenow_production_deployment.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

### 12.2 Set Up Monitoring and Reporting

Configure ServiceNow reports and dashboards for operational visibility:

```bash
./run_playbook.sh ../ansible/servicenow_monitoring_setup.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout
```

## 13. Verify the Complete Integration

Use the comprehensive verification script to test all integration components:

```bash
./verify_complete_servicenow_integration.sh
```

## Troubleshooting

If you encounter issues with the Ansible Automation Platform deployment (e.g., pods stuck in a pending state), it is likely related to storage. You can troubleshoot by inspecting the Persistent Volume Claims (PVCs) and pod events in the `aap` namespace:

```bash
oc get pvc -n aap
oc describe pod <pod-name> -n aap
```