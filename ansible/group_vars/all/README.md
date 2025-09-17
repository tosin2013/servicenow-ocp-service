# Ansible Group Variables - Vault Configuration

This directory contains the encrypted vault file with all sensitive credentials for the ServiceNow-OpenShift integration project.

## 🔐 Security Overview

All sensitive information (passwords, tokens, API keys) is stored in an encrypted Ansible Vault file to ensure security and prevent credential exposure in version control.

## 📁 Files in this Directory

- **`vault.yml`** - Encrypted vault file containing all sensitive credentials
- **`vault.yml.template`** - Template file showing all required variables
- **`vault.yml.bak`** - Backup of previous vault configuration
- **`README.md`** - This documentation file

## 🚀 Quick Start

### 1. Initial Setup (First Time)

```bash
# Copy the template to create your vault file
cp ansible/group_vars/all/vault.yml.template ansible/group_vars/all/vault.yml

# Edit the vault file with your actual credentials
vi ansible/group_vars/all/vault.yml

# Encrypt the vault file
ansible-vault encrypt ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
```

### 2. Updating Existing Vault

```bash
# Decrypt and edit the vault file
ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# Or decrypt, edit manually, then re-encrypt
ansible-vault decrypt ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
vi ansible/group_vars/all/vault.yml
ansible-vault encrypt ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
```

### 3. Viewing Vault Contents

```bash
# View encrypted vault contents
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# View specific variables
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep servicenow
```

## 🔑 Required Credentials

### ServiceNow Configuration
- **`vault_servicenow_password`** - ServiceNow admin password
- **`vault_servicenow_admin_password`** - Alternative ServiceNow admin password variable
- **`vault_servicenow_client_secret`** - OAuth client secret for ServiceNow integration

### Keycloak/RH-SSO Configuration
- **`vault_keycloak_password`** - Keycloak admin password
- **`vault_rhsso_admin_password`** - Alternative Keycloak admin password variable

### OpenShift Configuration
- **`vault_openshift_token`** - OpenShift admin or service account token
- **`vault_openshift_client_secret`** - OAuth client secret for OpenShift integration

### Ansible Automation Platform Configuration
- **`vault_aap_password`** - AAP admin password

## 📋 How to Get Credentials

### ServiceNow Credentials
```bash
# Use your ServiceNow instance admin credentials
# Example: https://dev295398.service-now.com
# Username: admin
# Password: [Your ServiceNow admin password]
```

### Keycloak/RH-SSO Credentials
```bash
# Get Keycloak admin password from OpenShift secret
oc get secret credential-rhsso -n sso -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d

# Username is typically 'admin'
```

### OpenShift Token
```bash
# Get current user token
oc whoami -t

# Or create a service account token for automation
oc create serviceaccount servicenow-integration
oc adm policy add-cluster-role-to-user cluster-admin -z servicenow-integration
oc create token servicenow-integration
```

### AAP Credentials
```bash
# Get AAP admin password from OpenShift secret
oc get secret automation-controller-admin-password -n aap -o jsonpath='{.data.password}' | base64 -d

# Username is typically 'admin'
```

## 🔄 Variable Compatibility

The vault file includes multiple variable names for the same credentials to ensure compatibility across different playbooks and roles:

| Primary Variable | Alternative Variables | Used In |
|------------------|----------------------|---------|
| `vault_servicenow_password` | `servicenow_password`, `vault_servicenow_admin_password` | All ServiceNow playbooks |
| `vault_keycloak_password` | `rhsso_admin_password`, `vault_rhsso_admin_password` | Keycloak/RH-SSO roles |
| `vault_openshift_token` | `openshift_token`, `ocp_token` | OpenShift integration |
| `vault_aap_password` | `aap_password` | AAP configuration |

## 🛡️ Security Best Practices

1. **Never commit unencrypted vault files** - Always encrypt before committing
2. **Use strong passwords** - Generate complex passwords for all services
3. **Rotate credentials regularly** - Update passwords and tokens periodically
4. **Backup vault files** - Keep encrypted backups of your vault configuration
5. **Limit access** - Only share vault password with authorized team members

## 🔧 Troubleshooting

### Common Issues

**Vault decryption fails:**
```bash
# Check vault password file exists and is correct
cat .vault_pass
# Verify vault file is encrypted
file ansible/group_vars/all/vault.yml
```

**Variable not found errors:**
```bash
# Check if variable exists in vault
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep VARIABLE_NAME
```

**Playbook authentication failures:**
```bash
# Verify credentials are correct by testing manually
curl -u admin:PASSWORD https://dev295398.service-now.com/api/now/table/sys_user?sysparm_limit=1
```

### Recovery Procedures

**Lost vault password:**
1. If you have a backup of the unencrypted vault, use that
2. Otherwise, you'll need to recreate the vault with new credentials
3. Update all service passwords and tokens

**Corrupted vault file:**
1. Restore from `vault.yml.bak` if available
2. Use the template to recreate the vault file
3. Re-enter all credentials

## 📚 Related Documentation

- [GETTING_STARTED.md](../../../GETTING_STARTED.md) - Main setup guide
- [Security README](../../vars/SECURITY_README.md) - Additional security guidance
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

## 🆘 Support

If you encounter issues with vault configuration:

1. Check the troubleshooting section above
2. Verify all credentials are current and valid
3. Ensure the vault password file (`.vault_pass`) is correct
4. Review playbook logs for specific error messages

---

**⚠️ SECURITY REMINDER**: This vault contains sensitive credentials. Always encrypt before committing to version control!
