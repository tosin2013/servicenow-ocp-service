# Shell Scripts Reference Documentation

This document provides comprehensive documentation for all shell scripts in the ServiceNow-OpenShift integration project.

## Core Operational Scripts

### run_playbook.sh

**Purpose**: Wrapper script to execute Ansible playbooks using ansible-navigator with the correct execution environment.

**Location**: `/run_playbook.sh`

**Usage**:
```bash
./run_playbook.sh <playbook-path> [ansible-navigator-options]
```

**Description**: 
This script simplifies the execution of Ansible playbooks by automatically configuring the execution environment and setting up the proper context. It ensures all playbooks run with the custom ServiceNow execution environment container.

**Parameters**:
- `<playbook-path>`: Path to the Ansible playbook (relative to project root)
- `[ansible-navigator-options]`: Any additional ansible-navigator options (vault files, extra vars, etc.)

**Examples**:
```bash
# Run pre-flight checks
./run_playbook.sh ansible/preflight_checks.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# Run main playbook with stdout mode
./run_playbook.sh ansible/playbook.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass -m stdout

# Configure AAP
./run_playbook.sh ansible/configure_aap.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
```

**Prerequisites**:
- `ansible-navigator.yml` configuration file must exist in `execution-environment/` directory
- ServiceNow execution environment container must be available
- Must be run from project root directory

**Exit Codes**:
- `0`: Success
- `1`: Configuration file not found
- `>1`: ansible-navigator exit code

---

### validate_integration.sh

**Purpose**: Comprehensive health check script for all ServiceNow-OpenShift integration components.

**Location**: `/validate_integration.sh`

**Usage**:
```bash
./validate_integration.sh [--skip-servicenow] [--skip-aap] [--detailed]
```

**Description**: 
Performs automated validation of connectivity, authentication, and configuration across all four tiers of the integration: OpenShift, Keycloak, ServiceNow, and Ansible Automation Platform.

**Options**:
- `--skip-servicenow`: Skip ServiceNow connectivity tests
- `--skip-aap`: Skip AAP connectivity tests  
- `--detailed`: Show detailed test output and debugging information

**Test Categories**:

1. **OpenShift Cluster Connectivity**
   - Cluster API access validation
   - Authentication verification
   - Namespace availability checks

2. **Keycloak/RH-SSO Health**
   - Service availability
   - Realm configuration validation
   - Client configuration verification

3. **ServiceNow Integration**
   - API connectivity
   - Authentication validation
   - Business rules configuration
   - Catalog items verification

4. **Ansible Automation Platform**
   - Controller API access
   - Job template availability
   - Execution environment verification

**Exit Codes**:
- `0`: All tests passed
- `1`: One or more tests failed
- `2`: Script execution error

**Example Output**:
```
================================================
  ServiceNow-OpenShift Integration Validator
================================================

Testing: OpenShift cluster connectivity
✅ OpenShift cluster is accessible
✅ User has proper permissions

Testing: Keycloak/RH-SSO health
✅ Keycloak is responding
✅ Required realms are configured

Testing: ServiceNow integration
✅ ServiceNow API is accessible
✅ Business rules are configured

Testing: AAP integration  
✅ AAP controller is accessible
✅ Job templates are configured

Summary: 8 tests passed, 0 tests failed
```

---

### verify_servicenow_integration.sh

**Purpose**: End-to-end integration testing with ServiceNow request simulation.

**Location**: `/verify_servicenow_integration.sh`

**Usage**:
```bash
./verify_servicenow_integration.sh [--test-mode] [--cleanup]
```

**Description**: 
Creates a real ServiceNow catalog request and validates the complete workflow from request submission to OpenShift project creation.

**Options**:
- `--test-mode`: Use test data instead of real requests
- `--cleanup`: Clean up test resources after completion

**Workflow Steps**:
1. Validate prerequisites
2. Create ServiceNow catalog request
3. Monitor AAP job execution
4. Verify OpenShift project creation
5. Validate user access and permissions
6. Generate test report

**Prerequisites**:
- All integration components must be configured
- Valid ServiceNow credentials in vault
- AAP token must be configured
- OpenShift cluster access

---

## Utility Scripts

### approve_workflow.sh

**Purpose**: Automated workflow approval for ServiceNow requests.

**Location**: `/approve_workflow.sh`

**Usage**:
```bash
./approve_workflow.sh <request-number> [--auto-approve]
```

**Parameters**:
- `<request-number>`: ServiceNow request number (e.g., REQ0000123)
- `--auto-approve`: Skip manual confirmation

**Description**: 
Automates the approval process for ServiceNow catalog requests, advancing them through the workflow states required for AAP job execution.

---

### approve_workflow_secure.sh

**Purpose**: Secure workflow approval with enhanced authentication.

**Location**: `/approve_workflow_secure.sh`

**Usage**:
```bash
./approve_workflow_secure.sh <request-number> --mfa-token <token>
```

**Description**: 
Enhanced version of the approval script with multi-factor authentication and additional security checks.

---

### configure-openshift-packages.sh

**Purpose**: Configure required OpenShift operators and packages.

**Location**: `/configure-openshift-packages.sh`

**Usage**:
```bash
./configure-openshift-packages.sh [--install-operators] [--configure-rbac]
```

**Description**: 
Installs and configures necessary OpenShift operators including External Secrets Operator, RH-SSO Operator, and AAP Operator.

---

### fix-credentials.sh

**Purpose**: Repair and reset integration credentials.

**Location**: `/fix-credentials.sh`

**Usage**:
```bash
./fix-credentials.sh [--component <servicenow|keycloak|aap>] [--reset-all]
```

**Description**: 
Troubleshooting script to fix common credential and authentication issues across integration components.

---

## Directory-Specific Scripts

### scripts/ Directory

Contains operational and testing utilities:

- `add_aap_token.sh`: Add or update AAP API token in vault
- `clean_and_test_workflow.sh`: Clean environment and run full test workflow
- `cleanup-environment.sh`: Remove test resources and reset environment
- `community-cleanup.sh`: Community-specific cleanup procedures
- `comprehensive-site-validation.sh`: Full website and documentation validation
- `quick-site-test.sh`: Fast site validation
- `show_test_request_info.sh`: Display ServiceNow test request details
- `test-live-site-links.sh`: Test live site link validation
- `test-live-site-real.sh`: Real site testing with external validation
- `test_business_rule_logic.js`: JavaScript test for ServiceNow business rules

### debug/ Directory

Contains diagnostic and troubleshooting scripts organized by component:

#### AAP (Ansible Automation Platform)
- `01-check-aap-connectivity.sh`: Validate AAP API connectivity
- `02-check-specific-job.sh`: Check specific job template status

#### OpenShift
- `01-check-projects.sh`: List and validate OpenShift projects
- `02-check-specific-project.sh`: Detailed project status check

#### ServiceNow
- `01-check-catalog-items.sh`: Validate ServiceNow catalog configuration
- `02-check-specific-request.sh`: Check specific request status

### user-workflows/ Directory

Contains user-facing workflow automation:

#### Beginner Workflows
- `start-beginner-workflow.sh`: Simplified workflow for new users

#### Advanced Workflows  
- `start-simplified-workflow.sh`: Advanced automation workflow

#### Common Utilities
- `ansible-integration.sh`: Common Ansible integration functions
- `monitor-aap.sh`: AAP monitoring utilities
- `monitor-servicenow.sh`: ServiceNow monitoring utilities

---

## Script Development Guidelines

### Documentation Standards

All scripts should include:

1. **Header Comments**:
   ```bash
   #!/bin/bash
   #
   # Script Name: script-name.sh
   # Purpose: Brief description of what the script does
   # Author: Author name
   # Last Modified: Date
   #
   ```

2. **Usage Function**:
   ```bash
   usage() {
       echo "Usage: $0 [options] <parameters>"
       echo "Options:"
       echo "  -h, --help    Show this help message"
       echo "  -v, --verbose Enable verbose output"
       exit 1
   }
   ```

3. **Error Handling**:
   ```bash
   set -euo pipefail  # Exit on error, undefined vars, pipe failures
   ```

4. **Logging**:
   ```bash
   log() {
       echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
   }
   ```

### Testing Standards

- All scripts must include test functions
- Use `shellcheck` for static analysis
- Include integration tests where applicable
- Document expected exit codes

### Security Standards

- Never hardcode credentials
- Use vault for sensitive data
- Validate all user inputs
- Follow principle of least privilege

---

## Common Usage Patterns

### Running Ansible Playbooks
```bash
# Standard pattern for running playbooks
./run_playbook.sh ansible/<playbook>.yml \
  -e @ansible/group_vars/all/vault.yml \
  --vault-password-file .vault_pass \
  -m stdout
```

### Validation Workflow
```bash
# Full validation sequence
./validate_integration.sh --detailed
./verify_servicenow_integration.sh --test-mode
./scripts/comprehensive-site-validation.sh
```

### Troubleshooting Sequence
```bash
# Debug connectivity issues
./debug/aap/01-check-aap-connectivity.sh
./debug/servicenow/01-check-catalog-items.sh
./debug/openshift/01-check-projects.sh

# Fix common issues
./fix-credentials.sh --reset-all
./scripts/cleanup-environment.sh
```

---

## Best Practices

1. **Always run from project root**: Most scripts expect to be run from the project root directory
2. **Use vault for credentials**: Never pass credentials as command line arguments
3. **Check prerequisites**: Validate environment before running operational scripts
4. **Monitor outputs**: Check exit codes and log outputs for troubleshooting
5. **Test in development**: Use test mode options before running in production
6. **Follow the workflow**: Use scripts in the documented sequence for best results

---

## Troubleshooting

### Common Issues

1. **Script not found**: Ensure you're in the project root directory
2. **Permission denied**: Check script execute permissions (`chmod +x script.sh`)
3. **Container not found**: Ensure execution environment is built and available
4. **Vault password issues**: Verify `.vault_pass` file exists and has correct password
5. **Network connectivity**: Check firewall and network access to all components

### Getting Help

- Use `--help` option with any script for usage information
- Check script logs and exit codes for detailed error information
- Refer to the main documentation for component-specific troubleshooting
- Use debug scripts to isolate connectivity and configuration issues