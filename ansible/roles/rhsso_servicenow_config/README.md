# RHSSO ServiceNow Configuration Role

This Ansible role configures Red Hat Single Sign-On (Keycloak) for ServiceNow integration.

## Description

The role performs the following tasks:
- Creates a ServiceNow realm in Keycloak
- Configures ServiceNow OAuth client with proper redirect URIs
- Configures OpenShift OAuth client for cluster integration
- Sets up authentication flows and client secrets

## Requirements

- `community.general` Ansible collection
- `python-keycloak` Python library
- Access to a running Keycloak instance
- Admin credentials for Keycloak

## Role Variables

### Required Variables

```yaml
rhsso_external_url: "https://keycloak-sso.apps.example.com"
rhsso_admin_username: "admin"
rhsso_admin_password: "your-admin-password"
servicenow_oauth_secret: "your-servicenow-client-secret"
openshift_oauth_secret: "your-openshift-client-secret"
```

### Optional Variables

```yaml
# ServiceNow Configuration
servicenow_url: "https://dev123456.service-now.com"

# OpenShift Configuration
openshift_apps_domain: "apps.example.com"

# Realm Configuration
realm_name: "servicenow"
client_id: "servicenow-client"
ocp_client_id: "openshift"
```

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
- hosts: localhost
  roles:
    - rhsso_servicenow_config
  vars:
    rhsso_external_url: "https://keycloak-sso.apps.cluster.example.com"
    rhsso_admin_username: "admin"
    rhsso_admin_password: "secure-password"
    servicenow_oauth_secret: "servicenow-client-secret"
    openshift_oauth_secret: "openshift-client-secret"
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
