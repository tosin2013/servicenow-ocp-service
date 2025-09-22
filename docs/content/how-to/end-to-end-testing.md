# End-to-End Test Guide

## Overview

The updated `end_to_end_test.yml` playbook provides comprehensive testing of the ServiceNow-OpenShift integration with support for both **Flow Designer** and **Business Rules** approaches, plus manual fallback capabilities.

## Key Features

### 🏷️ **Tag-Based Execution**
Run specific parts of the test using Ansible tags for targeted testing and debugging.

### 🔄 **Dual Integration Support**
Tests both Business Rules and Flow Designer approaches automatically.

### 🛠️ **Manual Fallback**
If automatic triggering fails, the playbook can manually trigger AAP jobs to complete the workflow.

### 📊 **Comprehensive Monitoring**
Tracks the complete workflow from ServiceNow request creation through OpenShift project deployment.

## Available Tags

### **setup** - Configuration Check
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "setup" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```
- Checks Business Rules status
- Verifies Flow Designer workflows
- Validates Connection & Credential Aliases
- Displays integration configuration

### **catalog** - Request Creation
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "catalog" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```
- Creates ServiceNow catalog request
- Sets up test project with all required fields
- Returns request number for tracking

### **trigger** - Automatic Triggering
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "trigger" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```
- Changes request state to "in_process"
- Waits for automatic AAP job triggering
- Checks if Business Rules or Flow Designer responded
- Includes automatic trigger validation

### **manual_trigger** - Manual Fallback
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "manual_trigger" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```
- Manually triggers AAP job template
- Uses same parameters as automatic trigger
- Only runs if automatic triggering failed
- Updates ServiceNow request with job details

### **monitor** - Status Monitoring
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "monitor" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```
- Monitors ServiceNow request status
- Checks AAP job execution
- Verifies OpenShift project creation
- Validates CMDB updates

## Complete Workflow Test

### **Full End-to-End Test**
```bash
./run_playbook.sh ../ansible/end_to_end_test.yml -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

This runs all phases:
1. **Configuration Check** - Validates integration setup
2. **Request Creation** - Creates ServiceNow catalog request
3. **Automatic Triggering** - Tests Business Rules/Flow Designer
4. **Manual Fallback** - Triggers AAP manually if needed
5. **Status Monitoring** - Tracks completion and results

## Test Scenarios

### **Scenario 1: Flow Designer Working**
```bash
# Check configuration
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "setup" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout

# Create request and test Flow Designer
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "catalog,trigger" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout

# Monitor results
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "monitor" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

### **Scenario 2: Manual Testing**
```bash
# Create request only
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "catalog" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout

# Manually trigger AAP (bypass automatic)
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "manual_trigger" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout

# Check results
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "monitor" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

### **Scenario 3: Debugging Integration Issues**
```bash
# Check what's configured
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "setup" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout

# Test automatic triggering only
./run_playbook.sh ../ansible/end_to_end_test.yml --tags "trigger" -e @../ansible/group_vars/all/vault.yml --vault-password-file ../.vault_pass -m stdout
```

## Configuration Variables

### **Test Configuration**
- `wait_for_automatic_trigger: 60` - Seconds to wait for automatic triggering
- `manual_trigger_fallback: true` - Enable manual AAP triggering if automatic fails

### **AAP Configuration**
- `aap_controller_url` - AAP controller URL
- `aap_job_template_id: "9"` - Job template for OpenShift project creation
- `aap_token` - AAP API token from vault

## Expected Outcomes

### **✅ Success Indicators**
- ServiceNow request created with proper fields
- Request state changes to "in_process"
- AAP job launches (automatically or manually)
- OpenShift project created with correct configuration
- Keycloak users provisioned
- ServiceNow request updated with access information

### **🔍 Diagnostic Information**
- Business Rules status (active/inactive)
- Flow Designer workflows (configured/missing)
- Connection & Credential Aliases (present/missing)
- AAP job execution logs
- OpenShift project details
- ServiceNow request history

## Troubleshooting

### **No Automatic Triggering**
1. Check Business Rules: `--tags "setup"`
2. Verify Flow Designer: Check ServiceNow UI
3. Test manual trigger: `--tags "manual_trigger"`

### **AAP Job Failures**
1. Check AAP connectivity
2. Verify job template configuration
3. Review extra_vars mapping

### **OpenShift Issues**
1. Verify cluster connectivity
2. Check RBAC permissions
3. Review namespace creation logs

## Integration with Flow Designer

The test automatically detects and works with:
- **Flow Designer workflows** - Tests ServiceNow Flow Designer → AAP integration
- **Connection & Credential Aliases** - Validates AAP connection configuration
- **Business Rules** - Falls back to Business Rules if Flow Designer not configured

This provides a comprehensive testing framework that works regardless of which integration approach is currently active.

---

**Next Steps**: Run the setup check to see current configuration, then proceed with targeted testing based on your integration setup.
