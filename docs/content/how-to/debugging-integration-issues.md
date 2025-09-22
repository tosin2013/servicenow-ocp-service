---
title: Debugging Integration Issues
---

# Debugging ServiceNow-OpenShift Integration Issues

**A comprehensive guide to troubleshooting and debugging the three-tier integration using built-in debug tools**

## 🎯 Overview

The ServiceNow-OpenShift integration involves multiple components that can fail at different points. This guide provides systematic debugging approaches using the built-in debug suite.

## 🏗️ Integration Architecture

```
ServiceNow → AAP (Ansible) → OpenShift
    ↓           ↓              ↓
  Catalog    Job Templates   Projects
  Requests   Job Execution   Resources
  Workflows  Monitoring      Verification
```

## 🛠️ Debug Suite Location

All debug tools are located in the `debug/` directory:

```
debug/
├── run-full-debug.sh           # Master debug script
├── servicenow/                 # ServiceNow API debugging
│   ├── 01-check-catalog-items.sh
│   └── 02-check-specific-request.sh
├── aap/                        # AAP debugging
│   ├── 01-check-aap-connectivity.sh
│   └── 02-check-specific-job.sh
└── openshift/                  # OpenShift debugging
    ├── 01-check-projects.sh
    └── 02-check-specific-project.sh
```

## 🚀 Quick Start Debugging

### **Step 1: Run Full Debug Suite**
```bash
./debug/run-full-debug.sh
```

This provides a comprehensive overview of all three integration tiers and identifies which component has issues.

### **Step 2: Component-Specific Debugging**
Based on the results, drill down into specific components:

```bash
# ServiceNow issues
./debug/servicenow/01-check-catalog-items.sh

# AAP issues  
./debug/aap/01-check-aap-connectivity.sh

# OpenShift issues
./debug/openshift/01-check-projects.sh
```

## 🔍 Systematic Debugging Approach

### **1. ServiceNow Debugging**

#### **Check API Connectivity**
```bash
./debug/servicenow/01-check-catalog-items.sh
```

**What it checks:**
- ✅ ServiceNow API authentication
- 📋 Available catalog items
- 🔍 OpenShift-specific catalog items
- 📊 Recent catalog requests

#### **Debug Specific Request**
```bash
# Check most recent request
./debug/servicenow/02-check-specific-request.sh

# Check specific request by ID
./debug/servicenow/02-check-specific-request.sh REQ0010044
```

**What it shows:**
- 📝 Request details (state, approval, timeline)
- 🔗 Associated request items
- 💬 Work notes and comments
- 📊 Request progression through workflow states

### **2. AAP (Ansible) Debugging**

#### **Check AAP Connectivity**
```bash
./debug/aap/01-check-aap-connectivity.sh
```

**What it validates:**
- 🔐 AAP API authentication
- 👤 Current user permissions
- 📋 Available job templates
- ✅ OpenShift job template (ID: 9)
- 📊 Recent job executions

#### **Debug Specific Job**
```bash
# Check most recent job
./debug/aap/02-check-specific-job.sh

# Check specific job by ID
./debug/aap/02-check-specific-job.sh 68
```

**What it examines:**
- 📝 Job status, timeline, and output
- 🔍 Job events and task results
- 📊 Job variables and template info
- 🎯 Execution details and logs

### **3. OpenShift Debugging**

#### **Check Cluster Connectivity**
```bash
./debug/openshift/01-check-projects.sh
```

**What it verifies:**
- 🔐 OpenShift cluster connectivity
- 📋 All accessible projects
- 🔍 ServiceNow-created projects
- ⏰ Recently created projects
- 🛡️ User permissions

#### **Debug Specific Project**
```bash
./debug/openshift/02-check-specific-project.sh my-project-name
```

**What it inspects:**
- 📊 Project resources (pods, services, deployments)
- 🏷️ Labels and annotations
- 📝 Recent events
- 🛡️ Resource quotas and limits

## 🔧 Common Issues and Solutions

### **ServiceNow Issues**

#### **Authentication Failures**
```bash
# Symptoms: API calls return 401/403
# Debug: Check credentials in vault
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass | grep servicenow
```

#### **Catalog Item Not Found**
```bash
# Symptoms: No OpenShift catalog items
# Debug: Check catalog configuration
./debug/servicenow/01-check-catalog-items.sh | grep -i openshift
```

### **AAP Issues**

#### **Job Template Missing**
```bash
# Symptoms: Job template not found
# Debug: List all available templates
./debug/aap/01-check-aap-connectivity.sh | grep -A 10 "Job Templates"
```

#### **Job Execution Failures**
```bash
# Symptoms: Jobs fail or timeout
# Debug: Check specific job details
./debug/aap/02-check-specific-job.sh [JOB_ID]
```

### **OpenShift Issues**

#### **Project Creation Failures**
```bash
# Symptoms: Projects not created
# Debug: Check cluster connectivity and permissions
./debug/openshift/01-check-projects.sh
```

#### **Resource Issues**
```bash
# Symptoms: Pods not starting, resource limits
# Debug: Inspect specific project
./debug/openshift/02-check-specific-project.sh [PROJECT_NAME]
```

## 📊 Debug Session Example

Here's a typical debugging session for a failed workflow:

```bash
# 1. Start with full debug overview
./debug/run-full-debug.sh

# 2. ServiceNow shows issues - drill down
./debug/servicenow/01-check-catalog-items.sh

# 3. Check the most recent request
./debug/servicenow/02-check-specific-request.sh

# 4. Request looks good - check if AAP job was triggered
./debug/aap/02-check-specific-job.sh

# 5. AAP job failed - check OpenShift connectivity
./debug/openshift/01-check-projects.sh

# 6. Found the issue - insufficient permissions
# Fix permissions and re-run workflow
```

## 🔗 Integration with User Workflows

The debug tools complement the user workflows:

- **Before running workflows**: Use debug tools to verify system health
- **During workflow execution**: Monitor progress with component-specific tools
- **After workflow failures**: Use targeted debugging to identify root cause

## 📚 Related Documentation

- [User Workflows Guide](../tutorials/user-workflows-guide.md) - Main workflow documentation
- [Getting Started Guide](../tutorials/getting-started.md) - Initial setup
- [Troubleshooting Common Issues](../reference/troubleshooting-reference.md) - Error solutions

---

**💡 Pro Tip**: Always start with the full debug suite (`./debug/run-full-debug.sh`) to get a complete picture before diving into component-specific debugging.
