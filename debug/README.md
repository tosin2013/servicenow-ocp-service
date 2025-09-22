# ServiceNow-OpenShift Integration Debug Suite

This debug folder contains curl-based validation scripts to test each step of the ServiceNow-OpenShift integration process independently.

## 🎯 Purpose

The integration involves multiple components:
1. **ServiceNow** - Catalog requests and workflow management
2. **AAP (Ansible Automation Platform)** - Job template execution
3. **OpenShift** - Project creation and resource management

These debug scripts help isolate issues at each integration point using direct API calls.

## 📁 Structure

```
debug/
├── servicenow/          # ServiceNow API validation
├── aap/                 # AAP API validation  
├── openshift/           # OpenShift CLI validation
├── run-full-debug.sh    # Master script (runs all checks)
└── README.md           # This file
```

## 🚀 Quick Start

### Run Full Debug Suite
```bash
./debug/run-full-debug.sh
```

### Run Individual Component Checks
```bash
# ServiceNow checks
./debug/servicenow/01-check-catalog-items.sh
./debug/servicenow/02-check-specific-request.sh [REQUEST_ID]

# AAP checks  
./debug/aap/01-check-aap-connectivity.sh
./debug/aap/02-check-specific-job.sh [JOB_ID]

# OpenShift checks
./debug/openshift/01-check-projects.sh
./debug/openshift/02-check-specific-project.sh [PROJECT_NAME]
```

## 📋 ServiceNow Debug Scripts

### `01-check-catalog-items.sh`
- ✅ Validates ServiceNow API connectivity
- 📋 Lists all active catalog items
- 🔍 Identifies OpenShift-specific catalog items
- 📊 Shows recent catalog requests

### `02-check-specific-request.sh [REQUEST_ID]`
- 🎯 Examines specific ServiceNow request details
- 📝 Shows request state, approval status, and timeline
- 🔗 Lists associated request items
- 💬 Displays work notes and comments

**Usage Examples:**
```bash
# Check most recent request
./debug/servicenow/02-check-specific-request.sh

# Check specific request
./debug/servicenow/02-check-specific-request.sh e522a7b547c03e50292cc82f316d43ec
```

## 🤖 AAP Debug Scripts

### `01-check-aap-connectivity.sh`
- 🔐 Tests AAP API authentication
- 👤 Shows current user permissions
- 📋 Lists available job templates
- ✅ Validates OpenShift job template (ID: 9)
- 📊 Shows recent job executions

### `02-check-specific-job.sh [JOB_ID]`
- 🎯 Examines specific AAP job execution
- 📝 Shows job status, timeline, and output
- 🔍 Lists job events and task results
- 📊 Displays job variables and template info

**Usage Examples:**
```bash
# Check most recent job
./debug/aap/02-check-specific-job.sh

# Check specific job
./debug/aap/02-check-specific-job.sh 68
```

## ☸️ OpenShift Debug Scripts

### `01-check-projects.sh`
- 🔐 Validates OpenShift connectivity
- 📋 Lists all accessible projects
- 🔍 Identifies ServiceNow-created projects
- ⏰ Shows recently created projects
- 🛡️ Checks user permissions

### `02-check-specific-project.sh [PROJECT_NAME]`
- 🎯 Examines specific OpenShift project
- 📊 Shows project resources (pods, services, deployments)
- 🏷️ Displays labels and annotations
- 📝 Lists recent events
- 🛡️ Shows resource quotas and limits

**Usage Examples:**
```bash
# Check specific project
./debug/openshift/02-check-specific-project.sh servicenow-real-1758225510
```

## 🔧 Troubleshooting Common Issues

### ServiceNow Issues
- **403 Forbidden**: User lacks permissions for system properties
- **Authentication Failed**: Check credentials in vault
- **No Catalog Items**: Verify ServiceNow instance setup

### AAP Issues  
- **Authentication Failed**: Check AAP token in vault
- **Job Template Not Found**: Verify template ID and permissions
- **Job Stuck**: Check AAP controller resources and logs

### OpenShift Issues
- **Not Connected**: Run `oc login` to authenticate
- **Project Not Found**: Verify project name and permissions
- **No Resources**: Check if AAP job completed successfully

## 📊 Integration Flow Validation

Use these scripts to validate the complete flow:

1. **ServiceNow Request Created** → `02-check-specific-request.sh`
2. **AAP Job Triggered** → `02-check-specific-job.sh`  
3. **OpenShift Project Created** → `02-check-specific-project.sh`

## 🔍 Example Debug Session

```bash
# 1. Run full debug to get overview
./debug/run-full-debug.sh

# 2. If issues found, drill down into specific components
./debug/servicenow/01-check-catalog-items.sh

# 3. Check the most recent request
./debug/servicenow/02-check-specific-request.sh

# 4. Check if AAP job was triggered
./debug/aap/02-check-specific-job.sh

# 5. Verify OpenShift project creation
./debug/openshift/01-check-projects.sh
```

## 🛠️ Configuration

Scripts use these configuration sources:
- **ServiceNow**: Uses vault-based credentials for secure authentication
- **AAP**: Token from `ansible/group_vars/all/vault.yml`
- **OpenShift**: Current `oc` login context

## 📝 Notes

- All scripts include colored output for better readability
- Scripts are designed to be safe (read-only operations)
- Error handling provides clear feedback on issues
- JSON output is formatted for human readability
