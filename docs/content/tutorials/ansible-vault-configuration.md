---
title: Ansible Vault Configuration Guide
---

# Ansible Vault Configuration Guide

This guide walks you through setting up the Ansible vault file with all required credentials for the ServiceNow-OpenShift integration.

## Overview

The ServiceNow-OpenShift integration requires credentials for multiple systems:
- **ServiceNow** - Admin credentials and OAuth secrets
- **Keycloak/RH-SSO** - Admin password for realm management
- **OpenShift** - Admin token for project creation
- **Ansible Automation Platform (AAP)** - Admin password and API token

All credentials are stored securely in an encrypted Ansible vault file.

## Prerequisites

- OpenShift cluster access with `oc` CLI configured
- ServiceNow Developer Instance (PDI) with admin access
- Basic understanding of Ansible vault concepts

## Step 1: Initial Vault Setup

### 1.1 Copy the Template

```bash
# Navigate to project root
cd /path/to/servicenow-ocp-service

# Copy the vault template
cp ansible/group_vars/all/vault.yml.template ansible/group_vars/all/vault.yml
```

### 1.2 Verify Vault Password File

```bash
# Check that vault password file exists
ls -la .vault_pass

# If missing, create it with a secure password
echo "your-secure-vault-password" > .vault_pass
chmod 600 .vault_pass
```

## Step 2: Gather Required Credentials

### 2.1 ServiceNow Credentials

**ServiceNow Admin Password:**
- Use your ServiceNow instance admin credentials
- Example instance: `https://dev295398.service-now.com`
- Username: `admin`
- Password: Your ServiceNow admin password

### 2.2 Keycloak/RH-SSO Credentials

```bash
# Get Keycloak admin password from OpenShift secret
oc get secret credential-rhsso -n sso -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d
```

### 2.3 OpenShift Token

```bash
# Get current user token
oc whoami -t

# Or create a service account token for automation (recommended)
oc create serviceaccount servicenow-integration
oc adm policy add-cluster-role-to-user cluster-admin -z servicenow-integration
oc create token servicenow-integration --duration=8760h  # 1 year
```

### 2.4 AAP Credentials

```bash
# Get AAP admin password from OpenShift secret
oc get secret automation-controller-admin-password -n aap -o jsonpath='{.data.password}' | base64 -d
```

### 2.5 AAP API Token (CRITICAL)

**This is the most important credential for ServiceNow integration:**

1. **Login to AAP Controller:**
   ```
   https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com
   ```

2. **Navigate to Token Management:**
   - Go to **Access → Users → admin → Tokens**
   - Click **"Add"** to create a new token

3. **Configure the Token:**
   - **Application Type**: "Personal access token"
   - **Description**: "ServiceNow Integration Token"
   - **Scope**: "Write" (required for job template execution)

4. **Copy the Token:**
   - **⚠️ IMPORTANT**: Copy the generated token immediately
   - The token is only shown once and cannot be retrieved later
   - Store it securely for the next step

## Step 3: Update Vault File

### 3.1 Edit the Vault File

```bash
# Edit the vault file with your actual credentials
vi ansible/group_vars/all/vault.yml
```

### 3.2 Replace Placeholder Values

Update these critical placeholders in the vault file:

```yaml
# ServiceNow Configuration
vault_servicenow_password: "YOUR_SERVICENOW_ADMIN_PASSWORD"
vault_servicenow_admin_password: "YOUR_SERVICENOW_ADMIN_PASSWORD"

# Keycloak/RH-SSO Configuration  
vault_keycloak_password: "KEYCLOAK_ADMIN_PASSWORD_FROM_SECRET"
vault_rhsso_admin_password: "KEYCLOAK_ADMIN_PASSWORD_FROM_SECRET"

# OpenShift Configuration
vault_openshift_token: "OPENSHIFT_TOKEN_FROM_OC_WHOAMI"

# AAP Configuration
vault_aap_password: "AAP_ADMIN_PASSWORD_FROM_SECRET"

# AAP API Token (CRITICAL for ServiceNow Integration)
vault_aap_token: "AAP_API_TOKEN_FROM_CONTROLLER"
```

### 3.3 Verify URLs and Configuration

Ensure these URLs match your environment:

```yaml
# Update these URLs to match your cluster
servicenow_url: "https://dev295398.service-now.com"
rhsso_url: "https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
openshift_api_url: "https://api.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com:6443"
openshift_apps_domain: "apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
aap_url: "https://ansible-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
```

## Step 4: Encrypt and Validate

### 4.1 Encrypt the Vault File

```bash
# Encrypt the vault file (NEVER commit unencrypted!)
ansible-vault encrypt ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# Verify encryption worked
file ansible/group_vars/all/vault.yml
# Should show: "ASCII text" (encrypted)
```

### 4.2 Test Vault Configuration

```bash
# Test vault decryption
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | head -10

# Test specific variables
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep vault_aap_token

# Verify ServiceNow credentials
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep servicenow
```

## Step 5: Validation Tests

### 5.1 Test ServiceNow Connectivity

```bash
# Test ServiceNow API access (replace with your credentials)
curl -u "admin:YOUR_PASSWORD" \
  "https://dev295398.service-now.com/api/now/table/sys_user?sysparm_limit=1"
```

### 5.2 Test AAP API Token

```bash
# Test AAP API token (replace with your token and URL)
curl -H "Authorization: Bearer YOUR_AAP_TOKEN" \
  "https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/api/v2/me/"
```

### 5.3 Run Pre-flight Checks

```bash
# Run the pre-flight check playbook to validate all credentials
./run_playbook.sh ../ansible/preflight_checks.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout
```

## Troubleshooting

### Common Issues

**Vault decryption fails:**
```bash
# Check vault password file
cat .vault_pass
# Verify vault file is encrypted
file ansible/group_vars/all/vault.yml
```

**AAP API token authentication fails:**
- Verify the token was copied correctly (no extra spaces/characters)
- Check token scope is set to "Write"
- Ensure token hasn't expired
- Test token manually with curl

**ServiceNow authentication fails:**
- Verify admin password is correct
- Check ServiceNow instance URL is accessible
- Ensure admin user is not locked

### Recovery Procedures

**Lost vault password:**
1. If you have a backup of the unencrypted vault, use that
2. Otherwise, recreate the vault using the template
3. Re-gather all credentials following this guide

**Invalid AAP token:**
1. Login to AAP Controller
2. Go to Access → Users → admin → Tokens
3. Delete the old token
4. Create a new token following Step 2.5
5. Update the vault file with the new token

## Security Best Practices

1. **Never commit unencrypted vault files** to version control
2. **Use strong, unique passwords** for all services
3. **Rotate credentials regularly**, especially API tokens
4. **Backup encrypted vault files** before making changes
5. **Limit access** to vault password and credentials

## Next Steps

After completing vault configuration:
1. Return to [Getting Started Guide](getting-started.md#step-3-infrastructure-configuration)
2. Run the infrastructure configuration playbooks
3. Proceed with ServiceNow integration setup

## Related Documentation

- [Ansible Vault Configuration README](../../ansible/group_vars/all/README.md)
- [AAP Token Setup Guide](../how-to/aap-token-setup.md)
- [Getting Started Guide](getting-started.md)
- [Complete Implementation Guide](../GETTING_STARTED.md)

---
*Ensure all credentials are properly encrypted before proceeding with the integration setup.*
