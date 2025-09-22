---
title: Ansible Reference
---

# Ansible Reference

**Complete technical reference for all Ansible playbooks, roles, and automation in the ServiceNow-OpenShift integration**

## 📋 Project Overview

The ServiceNow-OpenShift integration uses **30+ Ansible playbooks** and **5 custom roles** to automate the complete configuration of the four-tier architecture.

### Architecture Integration
- **Phase 1**: GitOps deploys infrastructure (AAP, Keycloak, External Secrets)
- **Phase 2**: Ansible configures applications (realms, clients, job templates)

## 📁 Directory Structure

```bash
ansible/
├── Core Configuration Playbooks
│   ├── playbook.yml                    # Main Keycloak configuration
│   ├── preflight_checks.yml           # Connectivity validation
│   ├── configure_aap.yml              # AAP job template setup
│   ├── oauth_integration_playbook.yml # OAuth configuration
│   └── openshift_oidc_playbook.yml    # OpenShift OIDC setup
├── ServiceNow Integration Playbooks
│   ├── servicenow_business_rules.yml  # Business Rules setup
│   ├── servicenow_catalog_setup.yml   # Catalog configuration
│   ├── servicenow_project_creation.yml # Project automation
│   └── servicenow_*.yml               # Additional ServiceNow tasks
├── Testing and Validation Playbooks
│   ├── end_to_end_test.yml           # Complete integration test
│   ├── idempotent_end_to_end_test.yml # Repeatable testing
│   ├── simple_e2e_test.yml           # Basic validation
│   └── test_*.yml                     # Specific component tests
├── Utility and Maintenance Playbooks
│   ├── cleanup_*.yml                  # Environment cleanup
│   ├── diagnose_*.yml                 # Troubleshooting
│   └── query_*.yml                    # Information gathering
└── Configuration and Variables
    ├── group_vars/all/vault.yml       # Encrypted credentials
    ├── vars/production.yml            # Production variables
    └── templates/                     # Jinja2 templates
```

## 🚀 Core Playbooks Reference

### 1. **playbook.yml** - Main Configuration
**Purpose**: Configure base Keycloak realms and ServiceNow OAuth integration

```yaml
# Execution
./run_playbook.sh ../ansible/playbook.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Key Variables
keycloak_admin_password: "{{ vault_keycloak_password }}"
servicenow_instance_url: "{{ vault_servicenow_url }}"
servicenow_oauth_client_id: "servicenow_oauth_client"

# Roles Used
- rhsso_servicenow_config

# Expected Outcomes
- ServiceNow realm created in Keycloak
- OAuth client configured
- ServiceNow OAuth profile set up
- Connection aliases created
```

### 2. **preflight_checks.yml** - Connectivity Validation
**Purpose**: Validate connectivity to all systems before configuration

```yaml
# Execution
./run_playbook.sh ../ansible/preflight_checks.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Checks Performed
- ServiceNow API connectivity
- Keycloak admin API access
- OpenShift cluster connectivity
- AAP controller access
- Credential validation

# Success Criteria
- All API endpoints return 200 status
- Authentication succeeds for all services
- Required permissions validated
```

### 3. **configure_aap.yml** - AAP Configuration
**Purpose**: Set up AAP job templates, projects, and credentials

```yaml
# Execution
./run_playbook.sh ../ansible/configure_aap.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Key Variables
aap_controller_url: "{{ vault_aap_controller_url }}"
aap_token: "{{ vault_aap_token }}"
git_repository_url: "https://github.com/tosin2013/servicenow-ocp-service.git"

# Resources Created
- AAP Project: "ServiceNow-OpenShift Integration"
- Job Template: "OpenShift Project Creation"
- Credentials: ServiceNow, OpenShift, Keycloak
- Inventory: localhost
```

### 4. **oauth_integration_playbook.yml** - OAuth Setup
**Purpose**: Configure OAuth integration between ServiceNow and Keycloak

```yaml
# Execution
./run_playbook.sh ../ansible/oauth_integration_playbook.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Configuration Steps
1. Create OAuth application registry in ServiceNow
2. Configure OAuth profiles
3. Set up connection aliases
4. Test OAuth flow
5. Validate token exchange

# Key Endpoints
- ServiceNow: /oauth_app_registry.do
- Keycloak: /realms/servicenow/protocol/openid-connect/token
```

### 5. **openshift_oidc_playbook.yml** - OpenShift OIDC
**Purpose**: Configure OpenShift to use Keycloak for authentication

```yaml
# Execution
./run_playbook.sh ../ansible/openshift_oidc_playbook.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Configuration Applied
- OpenShift OAuth resource updated
- Keycloak identity provider added
- Group synchronization configured
- RBAC mappings created

# Key Variables
keycloak_openshift_client_id: "openshift"
keycloak_openshift_client_secret: "{{ vault_keycloak_openshift_secret }}"
openshift_oauth_issuer: "{{ vault_keycloak_url }}/realms/openshift"
```

## 🔧 Custom Roles Reference

### 1. **rhsso_servicenow_config**
**Location**: `ansible/roles/rhsso_servicenow_config/`

**Purpose**: Complete Keycloak-ServiceNow OAuth integration

**Key Tasks**:
```yaml
# Main tasks (tasks/main.yml)
- Create ServiceNow realm
- Configure realm settings
- Create OAuth client
- Set up client scopes
- Configure ServiceNow OAuth profile
- Create connection aliases
- Test OAuth connectivity
```

**Variables**:
```yaml
# Required variables
keycloak_admin_password: "{{ vault_keycloak_password }}"
servicenow_instance_url: "{{ vault_servicenow_url }}"
servicenow_username: "{{ vault_servicenow_username }}"
servicenow_password: "{{ vault_servicenow_password }}"

# Optional variables (with defaults)
keycloak_realm_name: "servicenow"
oauth_client_id: "servicenow_oauth_client"
oauth_client_secret: "{{ vault_servicenow_oauth_secret }}"
```

**Files Generated**:
- `/tmp/servicenow_oauth_config_summary.md`
- `/tmp/servicenow_oauth_test_results.md`

### 2. **openshift_oidc_integration**
**Location**: `ansible/roles/openshift_oidc_integration/`

**Purpose**: Configure OpenShift OIDC with Keycloak

**Key Tasks**:
```yaml
- Configure OpenShift OAuth resource
- Create Keycloak identity provider
- Set up group mappings
- Configure RBAC policies
- Test OIDC authentication flow
```

### 3. **aap_configuration**
**Location**: `ansible/roles/aap_configuration/`

**Purpose**: Configure AAP job templates and projects

**Key Tasks**:
```yaml
- Create AAP organization
- Set up Git-based projects
- Configure job templates
- Create credential types
- Set up inventories
- Configure notifications
```

### 4. **servicenow_flow_designer** (Legacy)
**Location**: `ansible/roles/servicenow_flow_designer/`

**Status**: Deprecated in favor of Business Rules (ADR-014)

**Purpose**: Configure ServiceNow Flow Designer workflows

### 5. **keycloak_user_management**
**Location**: `ansible/roles/keycloak_user_management/`

**Purpose**: Manage Keycloak users and groups

**Key Tasks**:
```yaml
- Create user groups
- Assign group roles
- Configure user attributes
- Set up group mappings
```

## 📊 Variable Reference

### Vault Variables (`group_vars/all/vault.yml`)

#### ServiceNow Configuration
```yaml
vault_servicenow_url: "https://dev123456.service-now.com"
vault_servicenow_username: "admin"
vault_servicenow_password: "ENCRYPTED_PASSWORD_PLACEHOLDER"
vault_servicenow_oauth_secret: "encrypted_oauth_secret"
```

#### Keycloak Configuration
```yaml
vault_keycloak_url: "https://keycloak-sso.apps.cluster.example.com"
vault_keycloak_password: "encrypted_admin_password"
vault_keycloak_openshift_secret: "encrypted_client_secret"
```

#### OpenShift Configuration
```yaml
vault_openshift_api_url: "https://api.cluster.example.com:6443"
vault_openshift_token: "encrypted_service_account_token"
vault_openshift_console_url: "https://console-openshift-console.apps.cluster.example.com"
```

#### AAP Configuration
```yaml
vault_aap_controller_url: "https://ansible-controller-aap.apps.cluster.example.com"
vault_aap_username: "admin"
vault_aap_password: "encrypted_admin_password"
vault_aap_token: "encrypted_api_token"
```

### Production Variables (`vars/production.yml`)
```yaml
# Environment-specific settings
deployment_environment: "production"
enable_ssl_verification: true
oauth_token_lifetime: 3600
keycloak_session_timeout: 1800

# Resource limits
max_concurrent_jobs: 10
job_timeout_seconds: 1800
```

## 🧪 Testing Playbooks Reference

### End-to-End Testing
```yaml
# Complete integration test
end_to_end_test.yml:
  - Tests ServiceNow → AAP → OpenShift flow
  - Creates test project
  - Validates RBAC
  - Cleans up resources

# Idempotent testing
idempotent_end_to_end_test.yml:
  - Repeatable test execution
  - Updates existing test data
  - Avoids duplicate resource creation
```

### Component Testing
```yaml
# API connectivity tests
test_servicenow_connection.yml: ServiceNow API validation
test_servicenow_oauth.yml: OAuth flow testing
test_oidc_flow_playbook.yml: OpenShift OIDC testing
test_rbac_playbook.yml: RBAC validation

# Service-specific tests
test_servicenow_catalog.yml: Catalog item testing
validate_business_rules.yml: Business Rules validation
validate_flow_designer.yml: Flow Designer testing (legacy)
```

## 🔄 Execution Patterns

### Standard Execution
```bash
# Using wrapper script (recommended)
./run_playbook.sh ../ansible/PLAYBOOK.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# Direct execution
cd ansible/
ansible-playbook PLAYBOOK.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

### Advanced Execution Options
```bash
# Check mode (dry run)
ansible-playbook PLAYBOOK.yml --check \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Verbose output
ansible-playbook PLAYBOOK.yml -vvv \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Tag-based execution
ansible-playbook PLAYBOOK.yml --tags "keycloak_setup" \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Step-by-step execution
ansible-playbook PLAYBOOK.yml --step \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

## 📈 Performance and Optimization

### Execution Times (Approximate)
| Playbook | Duration | Complexity |
|----------|----------|------------|
| `preflight_checks.yml` | 2-3 minutes | Low |
| `playbook.yml` | 5-8 minutes | Medium |
| `configure_aap.yml` | 3-5 minutes | Medium |
| `oauth_integration_playbook.yml` | 4-6 minutes | High |
| `openshift_oidc_playbook.yml` | 2-4 minutes | Medium |
| `end_to_end_test.yml` | 8-12 minutes | High |

### Optimization Tips
- **Use check mode** for validation
- **Tag tasks** for selective execution
- **Cache API responses** where possible
- **Run in parallel** when safe
- **Use execution environment** for consistency

## 🔗 Integration Points

### AAP Job Templates
| Local Playbook | AAP Job Template | ID |
|----------------|------------------|----|
| `playbook.yml` | "Configure Base Keycloak" | 8 |
| `servicenow_project_creation.yml` | "OpenShift Project Creation" | 9 |
| `oauth_integration_playbook.yml` | "ServiceNow OAuth Setup" | 10 |

### ServiceNow Business Rules
- **Trigger**: Catalog request state change to "In Process"
- **Action**: Call AAP job template via REST API
- **Payload**: Project name, environment, requester details

### OpenShift Integration
- **Service Account**: `servicenow-automation`
- **Permissions**: Project creation, RBAC management
- **Namespace Pattern**: `servicenow-{project-name}-{environment}`

---
*This reference provides complete technical details for all Ansible automation in the ServiceNow-OpenShift integration*
