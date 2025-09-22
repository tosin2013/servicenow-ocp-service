# 📋 Configuration Variables Reference

**Complete reference for all Ansible variables and configuration parameters used in the ServiceNow-OpenShift integration**

## 🎯 Overview

This reference documents all configurable variables organized by component and usage context. Variables are categorized as:

- **🔐 Vault Variables**: Encrypted sensitive data (passwords, tokens, secrets)
- **🌐 Environment Variables**: Environment-specific configuration
- **⚙️ Feature Variables**: Feature toggles and behavioral settings
- **📊 Resource Variables**: Resource limits, quotas, and sizing

## 🔐 Vault Variables (Encrypted)

### ServiceNow Authentication

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `vault_servicenow_password` | string | ServiceNow admin password | `"SecurePassword123!"` |
| `vault_servicenow_admin_password` | string | Alternative ServiceNow admin password | `"SecurePassword123!"` |
| `vault_servicenow_client_secret` | string | OAuth client secret for ServiceNow | `"servicenow-secret-2025"` |

### Keycloak/RH-SSO Authentication

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `vault_keycloak_password` | string | Keycloak admin password | `"KeycloakAdmin123!"` |
| `vault_rhsso_admin_password` | string | RH-SSO admin password | `"KeycloakAdmin123!"` |

### OpenShift Authentication

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `vault_openshift_token` | string | OpenShift cluster admin token | `"sha256~AbCdEf..."` |
| `vault_openshift_client_secret` | string | OAuth client secret for OpenShift | `"openshift-secret-2025"` |

### Ansible Automation Platform

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `vault_aap_password` | string | AAP admin password | `"AAPAdmin123!"` |
| `vault_aap_admin_password` | string | Alternative AAP admin password | `"AAPAdmin123!"` |

## 🌐 Environment Variables

### ServiceNow Configuration

| Variable | Type | Required | Description | Default |
|----------|------|----------|-------------|---------|
| `servicenow_url` | string | ✅ | ServiceNow instance URL | `"https://dev295398.service-now.com"` |
| `servicenow_username` | string | ✅ | ServiceNow admin username | `"admin"` |
| `servicenow_instance_url` | string | ❌ | Alternative instance URL | `"{{ servicenow_url }}"` |

### Keycloak/RH-SSO Configuration

| Variable | Type | Required | Description | Default |
|----------|------|----------|-------------|---------|
| `rhsso_url` | string | ✅ | Keycloak instance URL | `"https://keycloak-sso.apps.cluster.com"` |
| `rhsso_external_url` | string | ❌ | External Keycloak URL | `"{{ rhsso_url }}"` |
| `rhsso_admin_username` | string | ✅ | Keycloak admin username | `"admin"` |
| `servicenow_realm_name` | string | ✅ | Keycloak realm name | `"servicenow"` |

### OpenShift Configuration

| Variable | Type | Required | Description | Default |
|----------|------|----------|-------------|---------|
| `openshift_api_url` | string | ✅ | OpenShift API server URL | `"https://api.cluster.com:6443"` |
| `openshift_apps_domain` | string | ✅ | OpenShift apps domain | `"apps.cluster.com"` |
| `openshift_cluster_domain` | string | ❌ | Alternative cluster domain | `"{{ openshift_apps_domain }}"` |
| `ocp_console_url` | string | ❌ | OpenShift console URL | Auto-generated |

### Ansible Automation Platform

| Variable | Type | Required | Description | Default |
|----------|------|----------|-------------|---------|
| `aap_url` | string | ✅ | AAP controller URL | `"https://aap-controller.apps.cluster.com"` |
| `aap_username` | string | ✅ | AAP admin username | `"admin"` |
| `controller_host` | string | ❌ | Alternative AAP host | `"{{ aap_url }}"` |
| `controller_username` | string | ❌ | Alternative AAP username | `"{{ aap_username }}"` |
| `controller_validate_certs` | boolean | ❌ | Validate SSL certificates | `false` |

## ⚙️ Feature Configuration Variables

### OAuth Integration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `oauth_redirect_url` | string | ServiceNow OAuth redirect URL | `"https://instance.service-now.com/oauth_redirect.do"` |
| `oauth_app_name` | string | OAuth application name | `"Keycloak SSO Integration"` |
| `servicenow_client_id` | string | ServiceNow OAuth client ID | `"servicenow-client"` |
| `openshift_client_id` | string | OpenShift OAuth client ID | `"openshift"` |

### OIDC Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `oidc_name` | string | OIDC identity provider name | `"keycloak-oidc"` |
| `oidc_display` | string | OIDC display name | `"Keycloak SSO"` |
| `oidc_scopes` | list | OIDC scopes to request | `["openid", "profile", "email", "groups"]` |

### Flow Designer Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `user_provisioning_flow_name` | string | User provisioning flow name | `"Keycloak User Provisioning"` |
| `project_management_flow_name` | string | Project management flow name | `"OpenShift Project Management"` |
| `enable_user_provisioning` | boolean | Enable user provisioning flow | `true` |
| `enable_project_management` | boolean | Enable project management flow | `true` |

### Business Rules Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `business_rule_trigger_state` | string | ServiceNow state that triggers automation | `"3"` (Work in Progress) |
| `automation_fulfillment_level` | string | ServiceNow fulfillment automation level | `"Fully automated"` |

## 📊 Resource Configuration Variables

### OpenShift Resource Quotas

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `default_resource_quotas.requests_cpu` | string | Default CPU requests | `"4"` |
| `default_resource_quotas.requests_memory` | string | Default memory requests | `"8Gi"` |
| `default_resource_quotas.limits_cpu` | string | Default CPU limits | `"8"` |
| `default_resource_quotas.limits_memory` | string | Default memory limits | `"16Gi"` |
| `default_resource_quotas.pods` | string | Maximum pods per project | `"10"` |
| `default_resource_quotas.persistent_volume_claims` | string | Maximum PVCs per project | `"5"` |

### RBAC Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `default_openshift_roles` | list | Available OpenShift roles | `["view", "edit", "admin"]` |
| `default_cluster_role` | string | Default cluster role for OIDC users | `"view"` |
| `create_cluster_role_bindings` | boolean | Create cluster role bindings | `true` |

### Group Mappings

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `admin_groups` | list | Groups with admin privileges | `["cluster-admins", "openshift-admins"]` |
| `group_mappings.cluster_admins` | list | Keycloak groups for cluster admins | `["/cluster-admins", "/openshift-admins"]` |
| `group_mappings.developers` | list | Keycloak groups for developers | `["/developers", "/dev-team"]` |

## 🔧 Execution Environment Variables

### Ansible Navigator Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `execution_environment.image` | string | EE container image | `"quay.io/takinosh/servicenow-ocp-ee:latest"` |
| `execution_environment.pull_policy` | string | Container pull policy | `"never"` |
| `execution_environment.container_engine` | string | Container engine to use | `"auto"` |

### Environment Variables Passed to EE

| Variable | Type | Description | Usage |
|----------|------|-------------|-------|
| `ANSIBLE_ADMIN_USER` | string | Ansible admin username | Passed through to EE |
| `ANSIBLE_ADMIN_PASSWORD` | string | Ansible admin password | Passed through to EE |
| `ANSIBLE_HUB_TOKEN` | string | Red Hat Automation Hub token | Used for collection downloads |

## 🧪 Testing and Development Variables

### Test Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `create_test_user` | boolean | Create test user in Keycloak | `true` |
| `test_user_username` | string | Test user username | `"oidc-test-user"` |
| `test_user_password` | string | Test user password | `"TestPassword123!"` |
| `test_user_email` | string | Test user email | `"oidc-test@example.com"` |
| `test_user_groups` | list | Test user groups | `["/developers"]` |

### Feature Toggles

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `enable_keycloak_client_config` | boolean | Configure Keycloak clients | `true` |
| `enable_openshift_oauth_config` | boolean | Configure OpenShift OAuth | `true` |
| `enable_rbac_group_mappings` | boolean | Enable RBAC group mappings | `true` |
| `enable_oidc_flow_testing` | boolean | Enable OIDC flow testing | `true` |

## 📧 Notification Configuration

### Email Settings

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `notification_emails.openshift_ops` | string | OpenShift operations email | `"openshift-ops@company.com"` |
| `notification_emails.admin` | string | Admin notification email | `"admin@company.com"` |

### Alert Severity Mapping

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `alert_severity_mapping.critical.priority` | string | Critical alert priority | `"1"` |
| `alert_severity_mapping.warning.priority` | string | Warning alert priority | `"3"` |
| `alert_severity_mapping.info.priority` | string | Info alert priority | `"4"` |

## 🗂️ ServiceNow Table Configuration

### Table Names

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `user_request_table` | string | User request table | `"sc_request"` |
| `project_request_table` | string | Project request table | `"sc_req_item"` |
| `incident_table` | string | Incident table | `"incident"` |

## 🔄 Variable Compatibility Mappings

### Alternative Variable Names

| Primary Variable | Alternative Names | Purpose |
|------------------|-------------------|---------|
| `rhsso_url` | `rhsso_external_url` | Keycloak URL compatibility |
| `servicenow_url` | `servicenow_instance_url` | ServiceNow URL compatibility |
| `openshift_apps_domain` | `openshift_cluster_domain` | OpenShift domain compatibility |
| `vault_keycloak_password` | `rhsso_admin_password` | Password compatibility |

## 📝 Usage Examples

### Basic Variable File

```yaml
---
# vars/production.yml
servicenow_url: "https://prod.service-now.com"
rhsso_url: "https://keycloak.company.com"
openshift_api_url: "https://api.prod-cluster.com:6443"
openshift_apps_domain: "apps.prod-cluster.com"
```

### Vault File Template

```yaml
---
# group_vars/all/vault.yml (encrypted)
vault_servicenow_password: "SecurePassword123!"
vault_keycloak_password: "KeycloakAdmin123!"
vault_openshift_token: "sha256~AbCdEf..."
```

### Playbook Usage

```bash
# Using variables
ansible-playbook playbook.yml \
  -e @vars/production.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file .vault_pass
```

---

**📚 Related Documentation:**
- [Getting Started Guide](../GETTING_STARTED.md) - Setup instructions
- [Keycloak Integration Guide](../KEYCLOAK_INTEGRATION_GUIDE.md) - Identity configuration
- [Security Guide](../explanation/security-architecture.md) - Security best practices
