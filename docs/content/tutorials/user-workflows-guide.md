---
title: User Workflows Guide
---

# User Workflows Guide

This guide explains the user workflow scripts for ServiceNow-OpenShift integration testing and validation.

## Overview

The `user-workflows/` directory contains scripts for testing and demonstrating the complete ServiceNow-OpenShift integration workflow. These workflows are designed to work with the PDI (Personal Developer Instance) limitations documented in [ADR-013](../adrs/013-pdi-workaround-strategy-for-development.md).

## Workflow Architecture

Based on [ADR-014: Business Rules Over Flow Designer](../adrs/014-business-rules-over-flow-designer.md), the workflows implement:

- **Production Approach**: Business Rules for automatic ServiceNow → AAP integration
- **Development Workaround**: Simplified workflow scripts for PDI environment testing
- **Validation Strategy**: End-to-end testing with manual fallback mechanisms

## Available Workflows

### ✅ **Recommended: Simplified Advanced Workflow**

**File**: `user-workflows/advanced/start-simplified-workflow.sh`

**Status**: ✅ **CONFIRMED WORKING**

**Purpose**: Production-ready workflow that follows the GETTING_STARTED.md process

**Usage**:
```bash
cd user-workflows/advanced/
./start-simplified-workflow.sh [project-name] [environment] [mode]
```

**Modes**:
- `check-first` - Check existing requests before creating new ones
- `create-request` - Create ServiceNow catalog request only
- `verify-only` - Verify OpenShift project creation only
- `full` - Complete end-to-end workflow (default)

**Example**:
```bash
./start-simplified-workflow.sh test-project development full
```

**Features**:
- ✅ Integrates with existing vault configuration
- ✅ Uses `run_playbook.sh` infrastructure
- ✅ Follows ADR-013 PDI workaround strategy
- ✅ Comprehensive error handling and reporting
- ✅ Real-time monitoring across all systems

### ✅ **Beginner Workflow**

**File**: `user-workflows/beginner/start-beginner-workflow.sh`

**Status**: ✅ **SECURE AND FUNCTIONAL**

**Purpose**: Step-by-step learning workflow with manual interactions

**Features**:
- ✅ Uses vault configuration for secure credential management
- ✅ Educational explanations at each step
- ✅ Manual approval process for learning
- ✅ Visual confirmation of results
- ✅ Integrates with existing infrastructure

**Usage**:
```bash
cd user-workflows/beginner/
./start-beginner-workflow.sh
```

**Recommendation**: Ideal for training and understanding the complete workflow process

### ✅ **Common Utilities**

**Files**: `user-workflows/common/monitor-aap.sh`, `user-workflows/common/monitor-servicenow.sh`

**Status**: ✅ **SECURE AND FUNCTIONAL**

**Purpose**: Real-time monitoring utilities for AAP and ServiceNow systems

**Features**:
- ✅ Secure vault-based credential management
- ✅ Real-time status monitoring
- ✅ Comprehensive error handling
- ✅ Multiple output formats (JSON, table, summary)

**Usage**:
```bash
# Monitor AAP jobs and connectivity
cd user-workflows/common/
./monitor-aap.sh test
./monitor-aap.sh jobs 5

# Monitor ServiceNow requests and incidents
./monitor-servicenow.sh test
./monitor-servicenow.sh requests
```

## ✅ **Security Status: SECURE**

All user-workflows scripts now use secure credential management:

1. **Vault Integration**: All scripts source credentials from `ansible/group_vars/all/vault.yml`
2. **No Hardcoded Credentials**: All previous security issues have been resolved
3. **Proper Access Controls**: Vault files use appropriate permissions
4. **Environment Isolation**: Credentials are environment-specific

### **Security Implementation**

All scripts use this secure pattern:
```bash
load_vault_config() {
    local vault_file="../../ansible/group_vars/all/vault.yml"
    local vault_pass="../../.vault_pass"

    if [[ -f "$vault_pass" && -f "$vault_file" ]]; then
        # Decrypt and source vault configuration
        eval $(ansible-vault view "$vault_file" --vault-password-file "$vault_pass" | grep -E '^[A-Z_]+=')
    else
        print_error "Vault configuration not found"
        return 1
    fi
}
```

## Workflow Integration

### **With Ansible Infrastructure**

The workflows integrate with the existing Ansible infrastructure:

```bash
# Uses existing vault configuration
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# Uses existing playbook runner
./run_playbook.sh ../ansible/idempotent_end_to_end_test.yml \
  -e @../ansible/group_vars/all/vault.yml \
  --vault-password-file ../.vault_pass -m stdout
```

### **With ADR Decisions**

- **ADR-013**: Implements PDI workaround strategy with manual triggers
- **ADR-014**: Aligns with Business Rules approach for production readiness
- **ADR-010**: Integrates with Ansible Automation Platform configuration

## Testing Strategy

### **Recommended Testing Approach**

1. **Start with Simplified Workflow**:
   ```bash
   cd user-workflows/advanced/
   ./start-simplified-workflow.sh test-project development check-first
   ```

2. **Validate Each Component**:
   ```bash
   # Test ServiceNow integration
   ./start-simplified-workflow.sh test-project development create-request
   
   # Test OpenShift integration
   ./start-simplified-workflow.sh test-project development verify-only
   ```

3. **Run Full End-to-End Test**:
   ```bash
   ./start-simplified-workflow.sh test-project development full
   ```

### **Validation Checklist**

- [ ] ServiceNow catalog request created successfully
- [ ] AAP job template triggered (manual or automatic)
- [ ] OpenShift project created and accessible
- [ ] All credentials sourced from vault (no hardcoded values)
- [ ] Error handling works correctly
- [ ] Monitoring and logging functional

## Documentation Updates Needed

### **High Priority**

1. **Update monitoring scripts** to remove hardcoded credentials
2. **Test beginner workflow** and update or deprecate
3. **Create security guidelines** for workflow development

### **Medium Priority**

1. **Add workflow diagrams** showing the complete process
2. **Document troubleshooting procedures** for common issues
3. **Create integration tests** for workflow validation

### **Low Priority**

1. **Add performance metrics** collection
2. **Implement workflow versioning** strategy
3. **Create workflow templates** for new use cases

## Migration Path

### **From Current State to Secure State**

1. **Immediate (Today)**:
   - Rotate exposed credentials
   - Update monitoring scripts to use vault
   - Test simplified workflow

2. **Short-term (This Week)**:
   - Update or deprecate beginner workflow
   - Create security guidelines
   - Document current working state

3. **Long-term (Next Month)**:
   - Implement comprehensive testing
   - Add monitoring and metrics
   - Create workflow templates

## Related Documentation

- [Getting Started Guide](getting-started.md) - Main setup process
- [Ansible Vault Configuration](ansible-vault-configuration.md) - Credential management
- [ADR-013: PDI Workaround Strategy](../adrs/013-pdi-workaround-strategy-for-development.md)
- [ADR-014: Business Rules Over Flow Designer](../adrs/014-business-rules-over-flow-designer.md)
- [End-to-End Test Guide](../how-to/end-to-end-testing.md) - Comprehensive testing

---
*Ensure all credentials are properly secured before using workflows in any environment.*
