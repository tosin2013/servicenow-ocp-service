# OpenShift Project Templates

This directory contains Jinja2 templates for creating OpenShift projects through ServiceNow integration. The templates are modular and can be customized for different use cases.

## Current Templates

### Core Templates

1. **`namespace.yaml.j2`** - Creates the OpenShift namespace/project
2. **`rbac-permissions.yaml.j2`** - Sets up user permissions and role bindings
3. **`resource-quotas.yaml.j2`** - Defines resource limits and quotas
4. **`network-policies.yaml.j2`** - Configures network security policies

## Template Variables

### Required Variables
- `project_name` - Name of the OpenShift project
- `display_name` - Human-readable project name
- `requestor` - Username of the person requesting the project
- `servicenow_request_number` - ServiceNow request number
- `environment` - Target environment (development, staging, production)
- `team` - Team or department name

### Optional Variables
- `project_description` - Project description
- `servicenow_request_item` - ServiceNow request item number
- `servicenow_sys_id` - ServiceNow system ID
- `project_type` - Type of project (standard, virtualization, ai-ml, etc.)
- `team_members` - List of additional team members
- `enable_cicd` - Enable CI/CD service account (default: false)
- `enable_web_services` - Enable web ingress (default: false)
- `enable_monitoring` - Enable monitoring access (default: true)
- `allow_internal_communication` - Allow internal namespace communication (default: true)

### Resource Quota Variables
- `cpu_requests` / `cpu_limits` - CPU resource limits
- `memory_requests` / `memory_limits` - Memory resource limits
- `max_pods` - Maximum number of pods
- `max_pvcs` - Maximum persistent volume claims
- `storage_requests` - Storage quota
- `storage_class` - Storage class for quotas
- `max_services` / `max_secrets` / `max_configmaps` - Object count limits

## Usage in Playbooks

```yaml
- name: Create OpenShift Project from Templates
  kubernetes.core.k8s:
    state: present
    host: "{{ openshift_api_url }}"
    api_key: "{{ openshift_auth.api_key }}"
    validate_certs: false
    definition: "{{ lookup('template', 'namespace.yaml.j2') | from_yaml }}"

- name: Apply RBAC Permissions
  kubernetes.core.k8s:
    state: present
    host: "{{ openshift_api_url }}"
    api_key: "{{ openshift_auth.api_key }}"
    validate_certs: false
    definition: "{{ lookup('template', 'rbac-permissions.yaml.j2') | from_yaml_all | list }}"
```

## Future Use Cases and Extensions

### 1. OpenShift Virtualization (CNV) Template

**File: `openshift-virtualization.yaml.j2`**

```yaml
---
# HyperConverged Cluster Configuration
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: "{{ project_name }}"
spec:
  infra:
    nodePlacement:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-role.kubernetes.io/worker
              operator: Exists

---
# Virtual Machine Template
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: "{{ vm_template_name | default('rhel8-vm') }}"
  namespace: "{{ project_name }}"
parameters:
- name: VM_NAME
  description: Name of the Virtual Machine
- name: VM_MEMORY
  description: Memory allocation for VM
  value: "{{ vm_memory | default('2Gi') }}"
- name: VM_CPU_CORES
  description: Number of CPU cores
  value: "{{ vm_cpu_cores | default('2') }}"
objects:
- apiVersion: kubevirt.io/v1
  kind: VirtualMachine
  metadata:
    name: "${VM_NAME}"
    namespace: "{{ project_name }}"
  spec:
    running: false
    template:
      metadata:
        labels:
          kubevirt.io/vm: "${VM_NAME}"
      spec:
        domain:
          cpu:
            cores: ${{VM_CPU_CORES}}
          resources:
            requests:
              memory: "${VM_MEMORY}"
          devices:
            disks:
            - name: rootdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
        volumes:
        - name: rootdisk
          containerDisk:
            image: "{{ vm_base_image | default('registry.redhat.io/rhel8/rhel-guest-image') }}"
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              user: cloud-user
              password: "{{ vm_default_password | default('redhat') }}"
              chpasswd: { expire: False }
```

### 2. AI/ML Workloads Template

**File: `ai-ml-workloads.yaml.j2`**

```yaml
---
# GPU Resource Quota (if GPU nodes available)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: "gpu-quota"
  namespace: "{{ project_name }}"
spec:
  hard:
    requests.nvidia.com/gpu: "{{ max_gpus | default('2') }}"
    limits.nvidia.com/gpu: "{{ max_gpus | default('2') }}"

---
# Jupyter Notebook Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "jupyter-notebook"
  namespace: "{{ project_name }}"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jupyter-notebook
  template:
    metadata:
      labels:
        app: jupyter-notebook
    spec:
      containers:
      - name: jupyter
        image: "{{ jupyter_image | default('jupyter/tensorflow-notebook:latest') }}"
        ports:
        - containerPort: 8888
        resources:
          requests:
            memory: "{{ jupyter_memory | default('4Gi') }}"
            cpu: "{{ jupyter_cpu | default('1') }}"
          limits:
            memory: "{{ jupyter_memory_limit | default('8Gi') }}"
            cpu: "{{ jupyter_cpu_limit | default('2') }}"
            nvidia.com/gpu: "{{ jupyter_gpu | default('1') }}"
```

### 3. Database Services Template

**File: `database-services.yaml.j2`**

```yaml
---
# PostgreSQL Database
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: "postgresql"
  namespace: "{{ project_name }}"
spec:
  serviceName: postgresql
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: "{{ postgres_image | default('registry.redhat.io/rhel8/postgresql-13') }}"
        env:
        - name: POSTGRESQL_DATABASE
          value: "{{ db_name | default('appdb') }}"
        - name: POSTGRESQL_USER
          value: "{{ db_user | default('appuser') }}"
        - name: POSTGRESQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: password
        volumeMounts:
        - name: postgresql-data
          mountPath: /var/lib/pgsql/data
  volumeClaimTemplates:
  - metadata:
      name: postgresql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: "{{ db_storage | default('10Gi') }}"
```

### 4. Monitoring and Observability Template

**File: `monitoring-stack.yaml.j2`**

```yaml
---
# ServiceMonitor for custom metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: "{{ project_name }}-metrics"
  namespace: "{{ project_name }}"
spec:
  selector:
    matchLabels:
      monitoring: "enabled"
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics

---
# Grafana Dashboard ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ project_name }}-dashboard"
  namespace: "{{ project_name }}"
  labels:
    grafana_dashboard: "1"
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "{{ display_name }} Metrics",
        "panels": [
          {
            "title": "CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{namespace=\"{{ project_name }}\"}[5m])"
              }
            ]
          }
        ]
      }
    }
```

## Adding New Templates

1. **Create the template file** in this directory with `.yaml.j2` extension
2. **Define required variables** at the top of the file as comments
3. **Use conditional blocks** for optional features
4. **Add environment-specific configurations** using Jinja2 conditionals
5. **Update the main playbook** to include the new template
6. **Test thoroughly** in development environment first

## Best Practices

1. **Use descriptive variable names** with prefixes (e.g., `vm_`, `db_`, `ai_`)
2. **Provide sensible defaults** for optional variables
3. **Include labels and annotations** for tracking and management
4. **Use environment-based conditionals** for different resource allocations
5. **Document all variables** in template comments
6. **Test templates** with various variable combinations

## ServiceNow Integration Variables

The following variables are automatically provided by the ServiceNow integration:

- `servicenow_request_number` - From ServiceNow request
- `servicenow_request_item` - Request item number
- `servicenow_sys_id` - System ID for tracking
- `requestor` - User who made the request
- `environment` - Selected environment
- `team` - Team assignment

Additional variables can be added to the ServiceNow catalog form and will be automatically passed to the templates.
