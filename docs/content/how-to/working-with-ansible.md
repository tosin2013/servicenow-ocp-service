---
title: Working with Ansible
---

# Working with Ansible

**Practical guide for developers on creating, testing, and debugging Ansible automation in the ServiceNow-OpenShift integration**

## 🎯 Overview

This guide provides step-by-step instructions for common Ansible development tasks that developers need to perform in the ServiceNow-OpenShift integration project.

## 🔧 Prerequisites

- **Ansible** installed (`pip install ansible`)
- **Project repository** cloned locally
- **Vault password** configured (`.vault_pass` file)
- **Basic understanding** of Ansible concepts

## 🚀 Quick Tasks

### Task 1: Run Existing Playbooks

**Goal**: Execute the main configuration playbooks

```bash
# 1. Navigate to project root
cd /path/to/servicenow-ocp-service

# 2. Run pre-flight checks
./run_playbook.sh ../ansible/preflight_checks.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# 3. Configure base Keycloak setup
./run_playbook.sh ../ansible/playbook.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout

# 4. Set up AAP configuration
./run_playbook.sh ../ansible/configure_aap.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout
```

### Task 2: Test Playbook Syntax

**Goal**: Validate playbook syntax before execution

```bash
# Test specific playbook
cd ansible/
ansible-playbook --syntax-check playbook.yml

# Test all playbooks
for playbook in *.yml; do
  echo "Checking $playbook..."
  ansible-playbook --syntax-check "$playbook"
done

# Test role syntax
ansible-playbook --syntax-check roles/rhsso_servicenow_config/tasks/main.yml
```

### Task 3: Run Playbooks in Check Mode

**Goal**: See what would change without making actual changes

```bash
# Check mode (dry run)
ansible-playbook playbook.yml --check \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Check mode with diff output
ansible-playbook playbook.yml --check --diff \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

## 🛠️ Development Tasks

### Task 4: Create a New Playbook

**Goal**: Create a new playbook for specific automation

```bash
# 1. Create new playbook file
cd ansible/
cat > my_new_playbook.yml << 'EOF'
---
- name: My New Automation Playbook
  hosts: localhost
  gather_facts: false
  vars_files:
    - group_vars/all/vault.yml
  
  tasks:
    - name: Example task
      debug:
        msg: "This is my new playbook"
    
    - name: Call external API
      uri:
        url: "{{ my_api_endpoint }}"
        method: GET
        headers:
          Authorization: "Bearer {{ my_api_token }}"
      register: api_response
    
    - name: Display API response
      debug:
        var: api_response.json
EOF

# 2. Test the new playbook
ansible-playbook --syntax-check my_new_playbook.yml

# 3. Run in check mode
ansible-playbook my_new_playbook.yml --check \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

### Task 5: Create a New Ansible Role

**Goal**: Create a reusable Ansible role

```bash
# 1. Create role structure
cd ansible/roles/
ansible-galaxy init my_new_role

# 2. Edit role tasks
cat > my_new_role/tasks/main.yml << 'EOF'
---
- name: Ensure required variables are defined
  assert:
    that:
      - my_role_variable is defined
      - my_role_api_url is defined
    fail_msg: "Required variables not defined"

- name: Configure my service
  uri:
    url: "{{ my_role_api_url }}/configure"
    method: POST
    body_format: json
    body:
      setting: "{{ my_role_variable }}"
    headers:
      Authorization: "Bearer {{ my_role_token }}"
  register: config_result

- name: Validate configuration
  uri:
    url: "{{ my_role_api_url }}/status"
    method: GET
    headers:
      Authorization: "Bearer {{ my_role_token }}"
  register: status_result
  failed_when: status_result.json.status != "configured"
EOF

# 3. Create role defaults
cat > my_new_role/defaults/main.yml << 'EOF'
---
my_role_variable: "default_value"
my_role_timeout: 30
EOF

# 4. Test the role
cat > test_my_role.yml << 'EOF'
---
- hosts: localhost
  roles:
    - my_new_role
  vars:
    my_role_api_url: "https://api.example.com"
    my_role_token: "{{ vault_my_api_token }}"
EOF

ansible-playbook --syntax-check test_my_role.yml
```

### Task 6: Add Variables to Vault

**Goal**: Add new encrypted variables to the vault

```bash
# 1. Decrypt vault temporarily
ansible-vault decrypt group_vars/all/vault.yml --vault-password-file ../.vault_pass

# 2. Add new variables
cat >> group_vars/all/vault.yml << 'EOF'

# My New Service Configuration
vault_my_api_token: "your-secret-token-here"
vault_my_service_password: "YOUR_SECRET_PASSWORD_HERE"
EOF

# 3. Re-encrypt vault (CRITICAL!)
ansible-vault encrypt group_vars/all/vault.yml --vault-password-file ../.vault_pass

# 4. Verify encryption
file group_vars/all/vault.yml
# Should show: "ASCII text" (encrypted)
```

### Task 7: Create Jinja2 Templates

**Goal**: Create dynamic configuration templates

```bash
# 1. Create template file
cat > templates/my_config.yaml.j2 << 'EOF'
# Generated configuration for {{ service_name }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ service_name }}-config
  namespace: {{ target_namespace }}
data:
  config.yaml: |
    service:
      name: {{ service_name }}
      port: {{ service_port | default(8080) }}
      environment: {{ deployment_environment }}
    
    database:
      host: {{ db_host }}
      port: {{ db_port | default(5432) }}
      name: {{ db_name }}
    
    features:
{% for feature in enabled_features %}
      - {{ feature }}
{% endfor %}
    
    oauth:
      client_id: {{ oauth_client_id }}
      issuer_url: {{ keycloak_url }}/realms/{{ keycloak_realm }}
EOF

# 2. Use template in playbook
cat > use_template.yml << 'EOF'
---
- name: Generate configuration from template
  hosts: localhost
  vars:
    service_name: "my-service"
    target_namespace: "my-namespace"
    deployment_environment: "development"
    enabled_features:
      - "feature1"
      - "feature2"
    oauth_client_id: "my-client"
    
  tasks:
    - name: Generate config from template
      template:
        src: templates/my_config.yaml.j2
        dest: /tmp/generated-config.yaml
    
    - name: Display generated config
      debug:
        msg: "{{ lookup('file', '/tmp/generated-config.yaml') }}"
EOF
```

## 🧪 Testing and Debugging

### Task 8: Debug Ansible Variables

**Goal**: Inspect and debug Ansible variables

```bash
# 1. Create debug playbook
cat > debug_vars.yml << 'EOF'
---
- name: Debug Variables
  hosts: localhost
  vars_files:
    - group_vars/all/vault.yml
  
  tasks:
    - name: Display all variables
      debug:
        var: vars
    
    - name: Display specific vault variables
      debug:
        msg: |
          ServiceNow URL: {{ vault_servicenow_url }}
          Keycloak URL: {{ vault_keycloak_url }}
          AAP URL: {{ vault_aap_controller_url }}
    
    - name: Display environment variables
      debug:
        var: ansible_env
    
    - name: Display facts
      debug:
        var: ansible_facts
EOF

# 2. Run debug playbook
ansible-playbook debug_vars.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

### Task 9: Test API Connectivity

**Goal**: Validate API endpoints and credentials

```bash
# Create API test playbook
cat > test_apis.yml << 'EOF'
---
- name: Test API Connectivity
  hosts: localhost
  vars_files:
    - group_vars/all/vault.yml
  
  tasks:
    - name: Test ServiceNow API
      uri:
        url: "{{ vault_servicenow_url }}/api/now/table/sys_user"
        method: GET
        user: "{{ vault_servicenow_username }}"
        password: "{{ vault_servicenow_password }}"
        force_basic_auth: yes
        validate_certs: no
      register: servicenow_test
      ignore_errors: yes
    
    - name: Display ServiceNow test result
      debug:
        msg: "ServiceNow API: {{ 'SUCCESS' if servicenow_test.status == 200 else 'FAILED' }}"
    
    - name: Test Keycloak Admin API
      uri:
        url: "{{ vault_keycloak_url }}/admin/realms"
        method: GET
        user: admin
        password: "{{ vault_keycloak_password }}"
        force_basic_auth: yes
        validate_certs: no
      register: keycloak_test
      ignore_errors: yes
    
    - name: Display Keycloak test result
      debug:
        msg: "Keycloak API: {{ 'SUCCESS' if keycloak_test.status == 200 else 'FAILED' }}"
    
    - name: Test AAP API
      uri:
        url: "{{ vault_aap_controller_url }}/api/v2/me/"
        method: GET
        headers:
          Authorization: "Bearer {{ vault_aap_token }}"
        validate_certs: no
      register: aap_test
      ignore_errors: yes
    
    - name: Display AAP test result
      debug:
        msg: "AAP API: {{ 'SUCCESS' if aap_test.status == 200 else 'FAILED' }}"
EOF

# Run API tests
ansible-playbook test_apis.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

### Task 10: Advanced Debugging Techniques

**Goal**: Use advanced debugging methods

```bash
# 1. Run with maximum verbosity
ansible-playbook playbook.yml -vvvv \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# 2. Use step-by-step execution
ansible-playbook playbook.yml --step \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# 3. Start from specific task
ansible-playbook playbook.yml \
  --start-at-task "Configure OAuth client" \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# 4. Use tags for selective execution
ansible-playbook playbook.yml --tags "keycloak_setup" \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# 5. Skip problematic tasks
ansible-playbook playbook.yml --skip-tags "servicenow_config" \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

## 🔄 Integration with AAP

### Task 11: Test Playbooks in Execution Environment

**Goal**: Test playbooks in the same environment as AAP

```bash
# 1. Run playbook in execution environment
ansible-navigator run playbook.yml \
  --execution-environment-image quay.io/takinosh/servicenow-ocp-ee:latest \
  --extra-vars @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass \
  --mode stdout

# 2. Interactive execution environment
ansible-navigator run playbook.yml \
  --execution-environment-image quay.io/takinosh/servicenow-ocp-ee:latest \
  --extra-vars @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass \
  --mode interactive
```

### Task 12: Prepare Playbooks for AAP

**Goal**: Ensure playbooks work correctly in AAP

```bash
# 1. Test without local files
ansible-playbook playbook.yml \
  --extra-vars @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass \
  --check

# 2. Validate all required variables are defined
ansible-playbook playbook.yml \
  --extra-vars @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass \
  --list-tasks

# 3. Test with minimal privileges
ansible-playbook playbook.yml \
  --extra-vars @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass \
  --become-method=su
```

## 🚨 Troubleshooting Common Issues

### Issue 1: Vault Decryption Errors

**Problem**: `ERROR! Attempting to decrypt but no vault secrets found`

**Solution**:
```bash
# Check vault file is encrypted
file group_vars/all/vault.yml

# Verify vault password file exists
ls -la ../.vault_pass

# Test vault decryption
ansible-vault view group_vars/all/vault.yml --vault-password-file ../.vault_pass
```

### Issue 2: Variable Not Found

**Problem**: `VARIABLE IS NOT DEFINED!`

**Solution**:
```bash
# Check variable definition
ansible-playbook playbook.yml --list-vars \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Debug specific variable
ansible-playbook debug_vars.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass
```

### Issue 3: API Connection Failures

**Problem**: Connection timeout or authentication errors

**Solution**:
```bash
# Test API connectivity
ansible-playbook test_apis.yml \
  -e @group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass

# Check network connectivity
curl -k "{{ vault_servicenow_url }}/api/now/table/sys_user"
```

## 📊 Best Practices

### ✅ **Do's**
- **Use vault** for all sensitive data
- **Test syntax** before running playbooks
- **Use check mode** for validation
- **Tag tasks** for selective execution
- **Document variables** in defaults/main.yml

### ❌ **Don'ts**
- **Don't commit** unencrypted vault files
- **Don't hardcode** credentials in playbooks
- **Don't skip** syntax validation
- **Don't run** untested playbooks in production
- **Don't ignore** failed tasks without investigation

## 🔗 Related Documentation

- **[Ansible Automation Tutorial](../tutorials/ansible-automation-guide.md)** - Understanding Ansible concepts
- **[Ansible Vault Configuration](../tutorials/ansible-vault-configuration.md)** - Credential management
- **[Ansible Reference](../reference/ansible-reference.md)** - Complete technical reference
- **[Execution Environment Guide](../tutorials/execution-environment-guide.md)** - Container environment

---
*Effective Ansible development is crucial for successful ServiceNow-OpenShift integration automation*
