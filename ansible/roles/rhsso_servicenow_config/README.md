# RHSSO ServiceNow OAuth Integration Role

This Ansible role provides **complete end-to-end OAuth integration** between Red Hat Single Sign-On (Keycloak) and ServiceNow, automating both Keycloak and ServiceNow-side configurations.

## Overview

This role implements the **hybrid GitOps and Ansible configuration** strategy (ADR-009) by:

1. **Keycloak Configuration**: Creates ServiceNow realm, OAuth clients, and authentication flows
2. **ServiceNow Configuration**: Uses ServiceNow REST APIs to automate OAuth profiles, application registry, and connection aliases
3. **Integration Testing**: Provides verification tasks to ensure proper OAuth flow

## Features

✅ **Fully Automated OAuth Setup**
- Creates ServiceNow realm in Keycloak
- Configures OAuth clients with proper redirect URIs  
- Automates ServiceNow OAuth profiles via REST API
- Sets up Connection & Credential Aliases
- Creates Application Registry entries

✅ **Production Ready**
- Error handling and validation
- Idempotent operations (safe to re-run)
- Comprehensive logging and status reporting
- Test playbook for verification

✅ **Security Best Practices**
- External variable injection for secrets
- Basic authentication with admin credentials
- Proper OAuth 2.0 authorization code flow

## Prerequisites

- **Ansible Collections**: `community.general`, `ansible.posix`
- **Python Libraries**: `python-keycloak`, `requests`
- **Network Access**: To both Keycloak and ServiceNow instances
- **Admin Credentials**: For both Keycloak and ServiceNow

## Quick Start

### 1. Install Dependencies
```bash
ansible-galaxy collection install community.general
pip install python-keycloak requests
```

### 2. Configure Variables
Create `vars/production.yml`:
```yaml
# Keycloak Configuration
rhsso_external_url: "https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
rhsso_admin_username: "admin"
rhsso_admin_password: "{{ vault_rhsso_admin_password }}"

# ServiceNow Configuration
servicenow_url: "https://dev295398.service-now.com"
servicenow_username: "admin"
servicenow_password: "{{ vault_servicenow_password }}"
servicenow_oauth_secret: "servicenow-secret-2025"

# OpenShift Configuration
openshift_apps_domain: "apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
openshift_oauth_secret: "openshift-secret-2025"
```

### 3. Run the Integration
```bash
# Full OAuth setup
ansible-playbook servicenow_playbook.yml -e @vars/production.yml

# Test OAuth integration
ansible-playbook test_servicenow_oauth.yml -e @vars/production.yml
```

## Role Variables

### Required Variables

```yaml
# Keycloak/RHSSO Configuration
rhsso_external_url: "https://keycloak-sso.apps.example.com"
rhsso_admin_username: "admin"
rhsso_admin_password: "your-keycloak-admin-password"

# ServiceNow Configuration  
servicenow_url: "https://dev123456.service-now.com"
servicenow_username: "admin"
servicenow_password: "your-servicenow-admin-password"
servicenow_oauth_secret: "your-servicenow-client-secret"

# OpenShift Configuration
openshift_oauth_secret: "your-openshift-client-secret"
```

### Optional Variables with Defaults

```yaml
# OAuth Application Settings
oauth_app_name: "Keycloak SSO Integration"
oauth_app_description: "OAuth 2.0 integration with Red Hat SSO/Keycloak"  
oauth_redirect_url: "https://dev295398.service-now.com/oauth_redirect.do"

# Client Configuration
realm_name: "servicenow"
client_id: "servicenow-client"
ocp_client_id: "openshift"

# Domain Configuration
# Domain Configuration
openshift_apps_domain: "apps.example.com"
```

## What This Role Creates

### In Keycloak:
- **ServiceNow Realm**: Isolated realm for ServiceNow integration
- **ServiceNow OAuth Client**: Client with ID `servicenow-client`
- **OpenShift OAuth Client**: Client for OpenShift cluster integration
- **Proper Redirect URIs**: Configured for OAuth authorization code flow

### In ServiceNow:
- **OAuth Entity Profile**: `keycloak_profile` pointing to Keycloak endpoints
- **OAuth2 Authentication Profile**: `Keycloak OAuth2 Profile` for REST message auth
- **Application Registry**: OAuth application entry for token management
- **Connection Alias**: `keycloak_connection` for outbound REST calls
- **Credential Alias**: `keycloak_credentials` for OAuth credentials

## Usage Examples

### Basic Role Usage
```yaml
- hosts: localhost
  roles:
    - role: rhsso_servicenow_config
      vars:
        rhsso_external_url: "{{ keycloak_url }}"
        servicenow_url: "{{ snow_instance_url }}"
        # ... other variables
```

### Advanced Configuration
```yaml
- name: Configure ServiceNow OAuth Integration
  hosts: localhost
  gather_facts: yes
  vars_files:
    - vars/production.yml
  roles:
    - role: rhsso_servicenow_config
  post_tasks:
    - name: Verify OAuth Integration
      include_tasks: roles/rhsso_servicenow_config/tasks/verify_oauth.yml
```

## Testing the Integration

### 1. Run Test Playbook
```bash
ansible-playbook test_servicenow_oauth.yml -e @vars/production.yml
```

### 2. Manual Verification in ServiceNow
1. Navigate to **System OAuth > Application Registry**
2. Find your OAuth application (default: "Keycloak SSO Integration")
3. Click **"Get OAuth Token"**
4. Verify redirect to Keycloak and successful authentication
5. Confirm token generation and storage

### 3. Manual Verification in Keycloak  
1. Go to Keycloak Admin Console
2. Navigate to **servicenow** realm
3. Check **Clients** section for `servicenow-client`
4. Verify client configuration and redirect URIs

## Integration Architecture

```
┌─────────────────┐    OAuth 2.0 Flow    ┌──────────────────┐
│   ServiceNow    │◄──────────────────────┤    Keycloak      │
│                 │                       │                  │
│ ┌─────────────┐ │   1. Authorization   │ ┌──────────────┐ │
│ │Application  │ │      Request         │ │ ServiceNow   │ │
│ │Registry     │ │◄─────────────────────┤ │ Realm        │ │
│ └─────────────┘ │                      │ └──────────────┘ │
│                 │   2. User Auth       │                  │
│ ┌─────────────┐ │◄─────────────────────┤ ┌──────────────┐ │
│ │OAuth2 Auth  │ │                      │ │ OAuth Client │ │
│ │Profile      │ │   3. Access Token    │ │ (servicenow- │ │
│ └─────────────┘ │◄─────────────────────┤ │ client)      │ │
│                 │                      │ └──────────────┘ │
│ ┌─────────────┐ │   4. API Calls       │                  │
│ │Connection   │ │◄─────────────────────┤                  │
│ │Alias        │ │   with Bearer Token  │                  │
│ └─────────────┘ │                      │                  │
└─────────────────┘                      └──────────────────┘
```

## Troubleshooting

### Common Issues

1. **ServiceNow API Authentication Failure**
   ```
   Solution: Verify ServiceNow admin credentials and instance URL
   Check: servicenow_username and servicenow_password variables
   ```

2. **Keycloak Connection Issues**
   ```
   Solution: Ensure Keycloak is accessible and admin credentials are correct
   Check: rhsso_external_url and rhsso_admin_password variables
   ```

3. **OAuth Profile Creation Fails**
   ```
   Solution: Check ServiceNow table permissions and API access
   Verify: Admin user has oauth_entity table write permissions
   ```

### Debugging

Enable verbose output:
```bash
ansible-playbook servicenow_playbook.yml -e @vars/production.yml -vvv
```

Check generated configuration:
```bash
cat /tmp/servicenow_oauth_config_summary.md
cat /tmp/servicenow_oauth_test_results.md
```

## Files Created

- `/tmp/servicenow_oauth_config_summary.md`: Complete configuration details
- `/tmp/servicenow_oauth_test_results.md`: Integration test results

## Security Considerations

- Store sensitive variables in encrypted files using `ansible-vault`
- Use external variable injection pattern for production deployments
- Regularly rotate OAuth client secrets
- Monitor OAuth token usage in ServiceNow logs

## Dependencies

None. This role is self-contained.

## License

Apache 2.0

## Author Information

This role was created as part of the ServiceNow OpenShift Platform Service integration project, implementing ADR-009 (Hybrid GitOps and Ansible Configuration) for complete OAuth automation.
```

## Example Playbook

### Basic Usage

```yaml
- hosts: localhost
  roles:
    - rhsso_servicenow_config
  vars:
    rhsso_external_url: "https://keycloak-sso.apps.cluster.example.com"
    rhsso_admin_username: "admin"
    rhsso_admin_password: "<your-rhsso-admin-password>"
    servicenow_oauth_secret: "<your-servicenow-oauth-secret>"
    openshift_oauth_secret: "<your-openshift-oauth-secret>"
```

### Using Variables File

```bash
# Create variables file
cp ansible/vars/template.yml ansible/vars/my-env.yml
# Edit with your values
vi ansible/vars/my-env.yml

# Run playbook
ansible-playbook ansible/playbook.yml -e @ansible/vars/my-env.yml
```

### Using Ansible Vault

```bash
# Encrypt sensitive variables
ansible-vault encrypt ansible/vars/production.yml

# Run with vault
ansible-playbook ansible/playbook.yml -e @ansible/vars/production.yml --ask-vault-pass
```

## Security Considerations

1. **Never commit secrets to git** - Use variables files excluded by .gitignore
2. **Use Ansible Vault** for production secrets
3. **Rotate client secrets** regularly
4. **Use least-privilege service accounts** for automation

## ADR Compliance

This role implements the hybrid GitOps + Ansible approach defined in:
- ADR-009: Hybrid GitOps and Ansible Configuration

The infrastructure (Keycloak deployment) is managed by GitOps, while application configuration (realms, clients) is managed by this Ansible role.

## License

BSD

## Author Information

Tosin Akinosho <takinosh@redhat.com>
