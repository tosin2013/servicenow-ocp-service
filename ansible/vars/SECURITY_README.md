# Security Configuration Guide

This project uses Ansible Vault to secure sensitive information like passwords and API keys.

## Required Vault Variables

Create an Ansible Vault file (e.g., `vault.yml`) with the following variables:

```yaml
---
# ServiceNow Configuration
vault_servicenow_password: "YOUR_SERVICENOW_PASSWORD"
vault_servicenow_admin_password: "YOUR_SERVICENOW_PASSWORD"

# Keycloak/RHSSO Configuration  
vault_rhsso_admin_password: "YOUR_KEYCLOAK_PASSWORD"
vault_keycloak_password: "YOUR_KEYCLOAK_PASSWORD"
```

## Usage

1. Create a vault file:
```bash
ansible-vault create ansible/vars/vault.yml
```

2. Add the vault file to your playbook runs:
```bash
ansible-playbook -e @vars/production.yml -e @vars/vault.yml --ask-vault-pass playbook.yml
```

3. Or specify it in ansible.cfg:
```ini
[defaults]
vault_password_file = .vault_pass
```

## Never Commit

- Never commit passwords or API keys to git
- Always use vault variables for sensitive data
- Add vault files to .gitignore
- Use environment variables for CI/CD systems

## Production Deployment

For production deployments, integrate with:
- HashiCorp Vault
- Azure Key Vault  
- AWS Secrets Manager
- OpenShift secrets

This ensures secure credential management at enterprise scale.
