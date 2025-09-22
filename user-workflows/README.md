# 🎯 OpenShift Project Creation Workflows

Complete end-to-end workflows for creating OpenShift projects through ServiceNow with AAP automation.

## 📋 **Workflow Options**

### 🎓 **Beginner Workflow** (`beginner/`)
**Perfect for learning and understanding each step**
- **Manual ServiceNow form submission**
- **Step-by-step approval guidance**
- **Manual monitoring of each system**
- **Educational explanations at each step**
- **Visual confirmation of results**

### 🚀 **Advanced Workflow** (`advanced/`)
**Fully automated end-to-end process**
- **Automated form submission**
- **Automatic approval and state management**
- **Real-time monitoring across all systems**
- **Automated result verification**
- **Complete hands-off experience**

### 🔧 **Common Tools** (`common/`)
**Shared utilities and monitoring scripts**
- **ServiceNow API helpers**
- **AAP job monitoring**
- **OpenShift project verification**
- **Status checking utilities**

## 🎯 **What Each Workflow Demonstrates**

### **End-to-End Process:**
1. **ServiceNow Request Creation** → Submit OpenShift project request
2. **Workflow Approval** → Move request through approval states
3. **AAP Job Launch** → Ansible automation triggers
4. **OpenShift Project Creation** → Actual infrastructure provisioning
5. **Status Monitoring** → Track progress across all systems
6. **Result Verification** → Confirm successful project creation

### **System Integration:**
- **ServiceNow** → Request management and tracking
- **Ansible Automation Platform** → Infrastructure automation
- **OpenShift** → Container platform provisioning
- **Incident Management** → Status tracking and notifications

## 🚀 **Quick Start**

### **For Learning (Beginner):**
```bash
cd beginner/
./start-beginner-workflow.sh
```

### **For Automation (Advanced):**
```bash
cd advanced/
./start-advanced-workflow.sh my-test-project
```

## 📊 **What You'll See**

### **ServiceNow:**
- ✅ Request creation and tracking
- ✅ Incident-based status updates
- ✅ Real-time job progress
- ✅ Automated state transitions
- 🔍 **Debug**: API connectivity, catalog items, request details

### **Ansible Automation Platform:**
- ✅ Job template execution
- ✅ Real-time job logs
- ✅ Success/failure status
- ✅ Job history tracking
- 🔍 **Debug**: Authentication, job templates, execution monitoring

### **OpenShift:**
- ✅ Project/namespace creation
- ✅ Resource allocation
- ✅ Access permissions
- ✅ Project verification
- 🔍 **Debug**: Connectivity, project status, resource inspection

## 🎯 **Learning Path**

1. **Start with Beginner** → Understand each manual step
2. **Review Common Tools** → Learn the monitoring utilities
3. **Progress to Advanced** → Experience full automation
4. **Customize Workflows** → Adapt for your environment

## 📋 **Prerequisites**

- **ServiceNow Access** → https://dev295398.service-now.com
- **AAP Access** → Ansible Controller credentials
- **OpenShift Access** → Cluster viewing permissions
- **Shell Environment** → Bash, curl, jq installed
- **Vault Configuration** → Properly configured `ansible/group_vars/all/vault.yml`

## 📚 **Documentation**

For comprehensive documentation, see:

- **[User Workflows Guide](../docs/content/tutorials/user-workflows-guide.md)** - Complete workflow documentation
- **[User Workflows Reference](../docs/content/reference/user-workflows-reference.md)** - Function reference and API documentation
- **[User Workflows Analysis](../docs/content/explanation/user-workflows-analysis.md)** - Architecture analysis and design decisions
- **[Getting Started Guide](../docs/content/GETTING_STARTED.md)** - Initial setup and configuration

## ✅ **Current Status**

All user-workflows are **SECURE AND FUNCTIONAL**:

- ✅ **Security**: All scripts use vault-based credential management
- ✅ **Testing**: Workflows tested and validated in development environment
- ✅ **Documentation**: Comprehensive documentation available
- ✅ **Integration**: Properly integrated with existing Ansible infrastructure

## 🔍 **Debugging & Troubleshooting**

### **Built-in Debug Features**
Each workflow includes:
- **Debug modes** for detailed logging
- **Status checking** utilities
- **Common error solutions**
- **Manual override options**

### **🛠️ Debug Suite** (`../debug/`)
**Comprehensive API-level debugging tools for isolating integration issues:**

#### **Quick Debug Commands**
```bash
# Run full debug suite across all components
./debug/run-full-debug.sh

# Test individual components
./debug/servicenow/01-check-catalog-items.sh
./debug/aap/01-check-aap-connectivity.sh
./debug/openshift/01-check-projects.sh
```

#### **Component-Specific Debugging**
- **ServiceNow**: API connectivity, catalog items, request tracking
- **AAP**: Authentication, job templates, execution monitoring
- **OpenShift**: Cluster connectivity, project status, resource inspection

#### **Targeted Troubleshooting**
```bash
# Debug specific ServiceNow request
./debug/servicenow/02-check-specific-request.sh [REQUEST_ID]

# Debug specific AAP job
./debug/aap/02-check-specific-job.sh [JOB_ID]

# Debug specific OpenShift project
./debug/openshift/02-check-specific-project.sh [PROJECT_NAME]
```

**📋 See [Debug Suite Documentation](../debug/README.md) for complete troubleshooting guide**

---

**Choose your path and start creating OpenShift projects! 🚀**
