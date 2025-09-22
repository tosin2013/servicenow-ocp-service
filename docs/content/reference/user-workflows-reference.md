---
title: User Workflows Reference
---

# 📚 User-Workflows Function Reference

This document provides comprehensive documentation for all functions used in the user-workflows scripts.

## 🎯 **Overview**

The user-workflows system consists of several shell scripts with well-defined functions for:
- **ServiceNow Integration**: API calls, request management, status monitoring
- **AAP (Ansible Automation Platform) Integration**: Job execution, monitoring, status checking
- **OpenShift Integration**: Project creation, verification, resource management
- **Workflow Orchestration**: End-to-end process management
- **Utility Functions**: Logging, formatting, error handling

## 📋 **Function Categories**

### 🖥️ **Display & Formatting Functions**

#### `print_header(message)`
**Purpose**: Display formatted section headers with consistent styling
**Parameters**: 
- `message` (string): Header text to display
**Returns**: 0 (always successful)
**Output**: Colored header with separator line

#### `print_info(message)`
**Purpose**: Display informational messages with consistent formatting
**Parameters**:
- `message` (string): Information text to display
**Returns**: 0 (always successful)
**Output**: Blue-colored informational message

#### `print_success(message)`
**Purpose**: Display success messages with green formatting
**Parameters**:
- `message` (string): Success message to display
**Returns**: 0 (always successful)
**Output**: Green-colored success message

#### `print_warning(message)`
**Purpose**: Display warning messages with yellow formatting
**Parameters**:
- `message` (string): Warning message to display
**Returns**: 0 (always successful)
**Output**: Yellow-colored warning message

#### `print_error(message)`
**Purpose**: Display error messages with red formatting
**Parameters**:
- `message` (string): Error message to display
**Returns**: 0 (always successful)
**Output**: Red-colored error message

### 🔐 **Authentication & Configuration Functions**

#### `load_vault_config()`
**Purpose**: Load and decrypt Ansible vault configuration
**Returns**: 0 if successful, 1 if failed
**Side Effects**: Sets environment variables for credentials
**Dependencies**: Requires vault.yml and .vault_pass files

#### `validate_prerequisites()`
**Purpose**: Validate that all required tools and credentials are available
**Returns**: 0 if all prerequisites met, 1 if missing requirements
**Checks**: curl, jq, oc commands, vault files, network connectivity

### 🌐 **ServiceNow Integration Functions**

#### `create_servicenow_request(project_name, environment)`
**Purpose**: Create a new ServiceNow catalog request for OpenShift project
**Parameters**:
- `project_name` (string): Name of the project to create
- `environment` (string): Target environment (dev/staging/prod)
**Returns**: 0 if successful, 1 if failed
**Output**: ServiceNow request number
**Side Effects**: Creates ServiceNow catalog item request

#### `check_servicenow_request_status(request_number)`
**Purpose**: Check the current status of a ServiceNow request
**Parameters**:
- `request_number` (string): ServiceNow request number (REQ0000000)
**Returns**: 0 if successful, 1 if failed
**Output**: Current request state and details

#### `approve_servicenow_request(request_number)`
**Purpose**: Approve a ServiceNow request and move it to Work in Progress
**Parameters**:
- `request_number` (string): ServiceNow request number to approve
**Returns**: 0 if successful, 1 if failed
**Side Effects**: Changes request state to "Work in Progress"

### 🤖 **AAP Integration Functions**

#### `trigger_aap_job(project_name, environment)`
**Purpose**: Trigger AAP job template execution for OpenShift project creation
**Parameters**:
- `project_name` (string): Name of the project to create
- `environment` (string): Target environment
**Returns**: 0 if successful, 1 if failed
**Output**: AAP job ID
**Side Effects**: Launches AAP job template

#### `monitor_aap_job(job_id)`
**Purpose**: Monitor AAP job execution status and progress
**Parameters**:
- `job_id` (string): AAP job ID to monitor
**Returns**: 0 if job successful, 1 if job failed
**Output**: Real-time job status and logs

#### `get_aap_job_logs(job_id)`
**Purpose**: Retrieve detailed logs from an AAP job execution
**Parameters**:
- `job_id` (string): AAP job ID
**Returns**: 0 if successful, 1 if failed
**Output**: Complete job execution logs

### ☸️ **OpenShift Integration Functions**

#### `verify_openshift_project(project_name)`
**Purpose**: Verify that an OpenShift project/namespace exists and is accessible
**Parameters**:
- `project_name` (string): Name of the project to verify
**Returns**: 0 if project exists, 1 if not found
**Output**: Project details and status

#### `check_project_resources(project_name)`
**Purpose**: Check resources and permissions within an OpenShift project
**Parameters**:
- `project_name` (string): Project name to check
**Returns**: 0 if successful, 1 if failed
**Output**: Resource list and access permissions

### 🔄 **Workflow Orchestration Functions**

#### `run_end_to_end_workflow(project_name, environment, mode)`
**Purpose**: Execute the complete end-to-end workflow
**Parameters**:
- `project_name` (string): Name of the project to create
- `environment` (string): Target environment
- `mode` (string): Execution mode (interactive/automated)
**Returns**: 0 if successful, 1 if failed
**Side Effects**: Creates ServiceNow request, triggers AAP job, verifies OpenShift project

#### `cleanup_failed_workflow(request_number)`
**Purpose**: Clean up resources from a failed workflow execution
**Parameters**:
- `request_number` (string): ServiceNow request number to clean up
**Returns**: 0 if successful, 1 if failed

### 🛠️ **Utility Functions**

#### `wait_for_condition(condition_function, timeout, interval)`
**Purpose**: Wait for a specific condition to be met with timeout
**Parameters**:
- `condition_function` (function): Function to check condition
- `timeout` (integer): Maximum wait time in seconds
- `interval` (integer): Check interval in seconds
**Returns**: 0 if condition met, 1 if timeout

#### `validate_project_name(project_name)`
**Purpose**: Validate project name meets OpenShift naming requirements
**Parameters**:
- `project_name` (string): Project name to validate
**Returns**: 0 if valid, 1 if invalid
**Validation Rules**: Lowercase, alphanumeric, hyphens allowed, max 63 chars

## 📊 **Usage Examples**

### **Basic Monitoring**
```bash
# Check AAP connectivity and recent jobs
./common/monitor-aap.sh test
./common/monitor-aap.sh jobs 5

# Check ServiceNow connectivity and requests
./common/monitor-servicenow.sh test
./common/monitor-servicenow.sh requests
```

### **Complete Workflow**
```bash
# Run the simplified workflow (recommended)
./advanced/start-simplified-workflow.sh my-project dev

# Run the beginner workflow (step-by-step)
./beginner/start-beginner-workflow.sh
```

## 🔍 **Troubleshooting**

Common function-related issues and solutions:

### **Authentication Issues**
- Verify vault.yml is properly decrypted
- Check .vault_pass file exists and is readable
- Validate network connectivity to ServiceNow and AAP

### **ServiceNow Integration Issues**
- Verify ServiceNow instance URL and credentials
- Check catalog item configuration
- Validate API permissions

### **AAP Integration Issues**
- Verify AAP controller URL and token
- Check job template configuration
- Validate execution environment availability

### **OpenShift Integration Issues**
- Verify oc command is available and configured
- Check cluster connectivity and authentication
- Validate project creation permissions

## 📚 **Related Documentation**

- [User Workflows Guide](../tutorials/user-workflows-guide.md) - Complete workflow documentation
- [Ansible Automation Guide](../tutorials/ansible-automation-guide.md) - AAP integration details
- [Getting Started Guide](../GETTING_STARTED.md) - Initial setup and configuration

---

*This reference is automatically maintained and reflects the current state of the user-workflows system.*
