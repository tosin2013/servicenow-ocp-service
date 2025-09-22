---
title: Working with Execution Environment
---

# Working with Execution Environment

**Practical guide for developers on building, testing, and customizing the ServiceNow-OpenShift integration execution environment**

## 🎯 Overview

This guide provides step-by-step instructions for common execution environment tasks that developers need to perform.

## 🔧 Prerequisites

- **Podman** or Docker installed
- **ansible-builder** installed (`pip install ansible-builder`)
- **Red Hat Automation Hub token** (for certified collections)
- **Git access** to the project repository

## 🚀 Quick Tasks

### Task 1: Test the Current Execution Environment

**Goal**: Verify the execution environment works correctly

```bash
# 1. Pull the latest image
podman pull quay.io/takinosh/servicenow-ocp-ee:latest

# 2. Test basic functionality
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible --version

# 3. List available collections
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest \
  ansible-galaxy collection list

# 4. Test specific collections
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest \
  ansible-doc servicenow.itsm.incident

podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest \
  ansible-doc kubernetes.core.k8s
```

### Task 2: Get Interactive Shell in Execution Environment

**Goal**: Explore the execution environment interactively

```bash
# Start interactive shell
podman run -it --rm quay.io/takinosh/servicenow-ocp-ee:latest /bin/bash

# Inside the container, you can:
ansible --version
python3 --version
oc version --client
ansible-galaxy collection list
ls -la /usr/share/ansible/collections/
```

### Task 3: Run Playbooks with Execution Environment

**Goal**: Execute playbooks using the custom execution environment

```bash
# Using ansible-navigator (recommended)
ansible-navigator run your-playbook.yml \
  --execution-environment-image quay.io/takinosh/servicenow-ocp-ee:latest \
  --mode stdout

# Using podman directly (for simple cases)
podman run --rm -v $(pwd):/workspace \
  quay.io/takinosh/servicenow-ocp-ee:latest \
  ansible-playbook /workspace/your-playbook.yml
```

## 🛠️ Building Custom Execution Environment

### Task 4: Build Execution Environment Locally

**Goal**: Build the execution environment from source

```bash
# 1. Navigate to execution environment directory
cd execution-environment/

# 2. Set your Red Hat Automation Hub token
export ANSIBLE_HUB_TOKEN="your_token_here"

# 3. Build using Makefile (recommended)
make build

# 4. Or build manually with ansible-builder
ansible-builder build \
  --tag servicenow-ocp-ee:local \
  --container-runtime podman \
  --verbosity 2
```

### Task 5: Add New Ansible Collection

**Goal**: Add a new collection to the execution environment

```bash
# 1. Edit the requirements file
vim execution-environment/files/requirements.yml

# 2. Add your collection
collections:
  - name: your.new.collection
    version: ">=1.0.0"

# 3. Rebuild the execution environment
cd execution-environment/
make build

# 4. Test the new collection
podman run --rm servicenow-ocp-ee:local \
  ansible-doc your.new.collection.module_name
```

### Task 6: Add Python Package

**Goal**: Add a Python package to the execution environment

```bash
# 1. Edit Python requirements
vim execution-environment/files/requirements.txt

# 2. Add your package
your-package-name==1.2.3

# 3. Rebuild
cd execution-environment/
make build

# 4. Test the package
podman run --rm servicenow-ocp-ee:local \
  python3 -c "import your_package_name; print('Success!')"
```

### Task 7: Add System Package

**Goal**: Add system-level packages to the execution environment

```bash
# 1. Edit system dependencies
vim execution-environment/files/bindep.txt

# 2. Add your package
your-system-package [platform:centos-8]

# 3. Rebuild
cd execution-environment/
make build

# 4. Test the package
podman run --rm servicenow-ocp-ee:local \
  which your-system-package
```

## 🧪 Testing and Validation

### Task 8: Validate Execution Environment

**Goal**: Comprehensive testing of the execution environment

```bash
# 1. Run the test suite
cd execution-environment/
make test

# 2. Test specific functionality
make test-collections
make test-tools
make test-connectivity

# 3. Manual validation
podman run --rm servicenow-ocp-ee:local \
  ansible-playbook --syntax-check /path/to/test-playbook.yml
```

### Task 9: Debug Execution Environment Issues

**Goal**: Troubleshoot problems with the execution environment

```bash
# 1. Check build logs
ansible-builder build --tag debug-ee --verbosity 3

# 2. Inspect the image
podman inspect servicenow-ocp-ee:local

# 3. Check for missing dependencies
podman run --rm servicenow-ocp-ee:local \
  ansible-galaxy collection list | grep -i missing

# 4. Test specific modules
podman run --rm servicenow-ocp-ee:local \
  ansible -m setup localhost
```

## 🔄 Development Workflow

### Task 10: Development Iteration Cycle

**Goal**: Efficient development workflow for EE changes

```bash
# 1. Make changes to EE configuration
vim execution-environment/files/requirements.yml

# 2. Quick build and test
cd execution-environment/
make build test

# 3. Test with actual playbooks
ansible-navigator run ../ansible/preflight_checks.yml \
  --execution-environment-image servicenow-ocp-ee:local \
  --mode stdout

# 4. If successful, tag and push
make tag push
```

### Task 11: Compare Execution Environments

**Goal**: Compare different versions of the execution environment

```bash
# 1. List collections in current version
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest \
  ansible-galaxy collection list > current-collections.txt

# 2. List collections in your build
podman run --rm servicenow-ocp-ee:local \
  ansible-galaxy collection list > local-collections.txt

# 3. Compare
diff current-collections.txt local-collections.txt
```

## 🚨 Troubleshooting Common Issues

### Issue 1: Collection Not Found

**Problem**: `ERROR! couldn't resolve module/action 'collection.module'`

**Solution**:
```bash
# Check if collection is installed
podman run --rm your-ee-image \
  ansible-galaxy collection list | grep collection.name

# If missing, add to requirements.yml and rebuild
```

### Issue 2: Python Package Import Error

**Problem**: `ModuleNotFoundError: No module named 'package_name'`

**Solution**:
```bash
# Check if package is installed
podman run --rm your-ee-image \
  python3 -c "import package_name"

# If missing, add to requirements.txt and rebuild
```

### Issue 3: System Command Not Found

**Problem**: `command not found: system-tool`

**Solution**:
```bash
# Check if tool is available
podman run --rm your-ee-image which system-tool

# If missing, add to bindep.txt and rebuild
```

### Issue 4: Authentication Issues

**Problem**: Collection download fails during build

**Solution**:
```bash
# Verify token is set
echo $ANSIBLE_HUB_TOKEN

# Check ansible.cfg configuration
cat execution-environment/files/ansible.cfg

# Rebuild with verbose output
ansible-builder build --verbosity 3
```

## 📊 Best Practices

### ✅ **Do's**
- **Pin collection versions** for reproducible builds
- **Test locally** before pushing to registry
- **Use semantic versioning** for your EE tags
- **Document custom changes** in commit messages
- **Keep builds minimal** - only add what you need

### ❌ **Don'ts**
- **Don't hardcode credentials** in the EE
- **Don't install unnecessary packages** (bloats image)
- **Don't skip testing** after changes
- **Don't use `latest` tags** in production
- **Don't commit sensitive tokens** to git

## 🔗 Related Documentation

- **[Execution Environment Tutorial](../tutorials/execution-environment-guide.md)** - Understanding EE concepts
- **[EE Reference](../reference/execution-environment-reference.md)** - Technical specifications
- **[ADR-011](../adrs/011-custom-execution-environment-for-aap.md)** - Architectural decisions
- **[Build Instructions](../../execution-environment/DEVELOPER_BUILD_INSTRUCTIONS.md)** - Detailed build process

---
*Efficient execution environment management is key to successful automation development*
