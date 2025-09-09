#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, ServiceNow OpenShift Integration Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: openshift_project_with_rbac
short_description: Create OpenShift project with RBAC and resource quotas
description:
  - Creates OpenShift project with automatic RBAC configuration
  - Configures role bindings for Keycloak-managed users
  - Sets up resource quotas and limit ranges
  - Integrates with ServiceNow request tracking
version_added: "1.0.0"
author:
  - ServiceNow OpenShift Integration Team
options:
  api_server:
    description:
      - OpenShift API server URL
    required: true
    type: str
  token:
    description:
      - OpenShift service account token for authentication
    required: true
    type: str
    no_log: true
  project_name:
    description:
      - Name of the OpenShift project to create
    required: true
    type: str
  display_name:
    description:
      - Display name for the project
    required: false
    type: str
  description:
    description:
      - Project description
    required: false
    type: str
  keycloak_users:
    description:
      - List of Keycloak users to grant access
    required: false
    type: list
    elements: str
  resource_quota:
    description:
      - Resource quota specifications
    required: false
    type: dict
    suboptions:
      cpu_requests:
        description: CPU requests limit
        type: str
        default: "4"
      memory_requests:
        description: Memory requests limit  
        type: str
        default: "8Gi"
      cpu_limits:
        description: CPU limits
        type: str
        default: "8"
      memory_limits:
        description: Memory limits
        type: str
        default: "16Gi"
      pods:
        description: Maximum number of pods
        type: str
        default: "10"
      storage_requests:
        description: Storage requests limit
        type: str
        default: "50Gi"
  limit_range:
    description:
      - Limit range specifications for containers
    required: false
    type: dict
    suboptions:
      default_cpu_request:
        description: Default CPU request for containers
        type: str
        default: "100m"
      default_memory_request:
        description: Default memory request for containers
        type: str
        default: "256Mi"
      default_cpu_limit:
        description: Default CPU limit for containers
        type: str
        default: "500m"
      default_memory_limit:
        description: Default memory limit for containers
        type: str
        default: "512Mi"
  servicenow_request_id:
    description:
      - ServiceNow request ID for tracking
    required: false
    type: str
  validate_certs:
    description:
      - Whether to validate SSL certificates
    default: true
    type: bool
  state:
    description:
      - Desired state of the project
    default: present
    choices: ['present', 'absent']
    type: str
'''

EXAMPLES = r'''
- name: Create OpenShift project with RBAC
  openshift_project_with_rbac:
    api_server: "https://api.cluster.example.com:6443"
    token: "{{ openshift_token }}"
    project_name: "development-team-a"
    display_name: "Development Team A"
    description: "Development environment for Team A"
    keycloak_users:
      - "john.doe@company.com"
      - "jane.smith@company.com"
    resource_quota:
      cpu_requests: "2"
      memory_requests: "4Gi"
      cpu_limits: "4"
      memory_limits: "8Gi"
      pods: "5"
      storage_requests: "20Gi"
    limit_range:
      default_cpu_request: "50m"
      default_memory_request: "128Mi"
      default_cpu_limit: "200m"
      default_memory_limit: "256Mi"
    servicenow_request_id: "REQ0001234"
    state: present
'''

RETURN = r'''
project:
  description: Created project information
  returned: success
  type: dict
  sample:
    name: "development-team-a"
    uid: "12345678-1234-1234-1234-123456789012"
    status: "Active"
role_bindings:
  description: Created role bindings
  returned: success
  type: list
  sample:
    - name: "admin-binding"
      role: "admin"
      users: ["john.doe@company.com"]
resource_quota:
  description: Created resource quota
  returned: success
  type: dict
  sample:
    name: "project-quota"
    limits:
      cpu: "4"
      memory: "8Gi"
limit_range:
  description: Created limit range
  returned: success
  type: dict
  sample:
    name: "project-limits"
    defaults:
      cpu: "100m"
      memory: "256Mi"
'''

from ansible.module_utils.basic import AnsibleModule
import requests
import json
import yaml


class OpenShiftProjectManager:
    def __init__(self, module):
        self.module = module
        self.api_server = module.params['api_server'].rstrip('/')
        self.token = module.params['token']
        self.validate_certs = module.params['validate_certs']
        
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }

    def _make_request(self, method, endpoint, data=None):
        """Make HTTP request to OpenShift API"""
        url = f"{self.api_server}{endpoint}"
        try:
            if method == 'GET':
                response = requests.get(url, headers=self.headers, 
                                      verify=self.validate_certs, params=data)
            elif method == 'POST':
                response = requests.post(url, headers=self.headers, 
                                       verify=self.validate_certs, json=data)
            elif method == 'PUT':
                response = requests.put(url, headers=self.headers, 
                                      verify=self.validate_certs, json=data)
            elif method == 'DELETE':
                response = requests.delete(url, headers=self.headers, 
                                         verify=self.validate_certs)
            
            if response.status_code in [200, 201, 202]:
                return response.json() if response.content else {}
            elif response.status_code == 404:
                return None
            else:
                response.raise_for_status()
                
        except requests.exceptions.RequestException as e:
            self.module.fail_json(msg=f"OpenShift API request failed: {str(e)}")

    def project_exists(self, project_name):
        """Check if project already exists"""
        result = self._make_request('GET', f'/api/v1/namespaces/{project_name}')
        return result is not None

    def create_project(self):
        """Create OpenShift project with full configuration"""
        project_name = self.module.params['project_name']
        display_name = self.module.params.get('display_name', project_name)
        description = self.module.params.get('description', f'Project {project_name}')
        servicenow_request_id = self.module.params.get('servicenow_request_id')
        
        if self.project_exists(project_name):
            return False, f"Project {project_name} already exists"

        # Create project request
        annotations = {
            'openshift.io/description': description,
            'openshift.io/display-name': display_name
        }
        
        if servicenow_request_id:
            annotations['servicenow.com/request-id'] = servicenow_request_id

        project_data = {
            'apiVersion': 'project.openshift.io/v1',
            'kind': 'ProjectRequest',
            'metadata': {
                'name': project_name,
                'annotations': annotations
            }
        }

        # Create the project
        project_result = self._make_request('POST', '/apis/project.openshift.io/v1/projectrequests', 
                                          project_data)
        
        if not project_result:
            self.module.fail_json(msg=f"Failed to create project {project_name}")

        results = {'project': project_result}

        # Create resource quota if specified
        resource_quota = self.module.params.get('resource_quota')
        if resource_quota:
            quota_result = self.create_resource_quota(project_name, resource_quota)
            results['resource_quota'] = quota_result

        # Create limit range if specified
        limit_range = self.module.params.get('limit_range')
        if limit_range:
            limit_result = self.create_limit_range(project_name, limit_range)
            results['limit_range'] = limit_result

        # Create role bindings for Keycloak users
        keycloak_users = self.module.params.get('keycloak_users', [])
        if keycloak_users:
            role_bindings = self.create_role_bindings(project_name, keycloak_users)
            results['role_bindings'] = role_bindings

        return True, results

    def create_resource_quota(self, project_name, quota_spec):
        """Create resource quota for the project"""
        quota_data = {
            'apiVersion': 'v1',
            'kind': 'ResourceQuota',
            'metadata': {
                'name': f'{project_name}-quota',
                'namespace': project_name
            },
            'spec': {
                'hard': {
                    'requests.cpu': quota_spec.get('cpu_requests', '4'),
                    'requests.memory': quota_spec.get('memory_requests', '8Gi'),
                    'limits.cpu': quota_spec.get('cpu_limits', '8'),
                    'limits.memory': quota_spec.get('memory_limits', '16Gi'),
                    'pods': quota_spec.get('pods', '10'),
                    'requests.storage': quota_spec.get('storage_requests', '50Gi')
                }
            }
        }

        return self._make_request('POST', f'/api/v1/namespaces/{project_name}/resourcequotas', 
                                quota_data)

    def create_limit_range(self, project_name, limit_spec):
        """Create limit range for the project"""
        limit_data = {
            'apiVersion': 'v1',
            'kind': 'LimitRange',
            'metadata': {
                'name': f'{project_name}-limits',
                'namespace': project_name
            },
            'spec': {
                'limits': [
                    {
                        'type': 'Container',
                        'default': {
                            'cpu': limit_spec.get('default_cpu_limit', '500m'),
                            'memory': limit_spec.get('default_memory_limit', '512Mi')
                        },
                        'defaultRequest': {
                            'cpu': limit_spec.get('default_cpu_request', '100m'),
                            'memory': limit_spec.get('default_memory_request', '256Mi')
                        }
                    }
                ]
            }
        }

        return self._make_request('POST', f'/api/v1/namespaces/{project_name}/limitranges', 
                                limit_data)

    def create_role_bindings(self, project_name, users):
        """Create role bindings for Keycloak users"""
        role_bindings = []
        
        # Create admin role binding for first user (project owner)
        if users:
            admin_binding = {
                'apiVersion': 'rbac.authorization.k8s.io/v1',
                'kind': 'RoleBinding',
                'metadata': {
                    'name': f'{project_name}-admin',
                    'namespace': project_name
                },
                'subjects': [
                    {
                        'kind': 'User',
                        'name': users[0],
                        'apiGroup': 'rbac.authorization.k8s.io'
                    }
                ],
                'roleRef': {
                    'kind': 'ClusterRole',
                    'name': 'admin',
                    'apiGroup': 'rbac.authorization.k8s.io'
                }
            }
            
            admin_result = self._make_request(
                'POST', 
                f'/apis/rbac.authorization.k8s.io/v1/namespaces/{project_name}/rolebindings',
                admin_binding
            )
            role_bindings.append(admin_result)

        # Create edit role binding for other users
        if len(users) > 1:
            edit_subjects = [
                {
                    'kind': 'User',
                    'name': user,
                    'apiGroup': 'rbac.authorization.k8s.io'
                } for user in users[1:]
            ]
            
            edit_binding = {
                'apiVersion': 'rbac.authorization.k8s.io/v1',
                'kind': 'RoleBinding',
                'metadata': {
                    'name': f'{project_name}-edit',
                    'namespace': project_name
                },
                'subjects': edit_subjects,
                'roleRef': {
                    'kind': 'ClusterRole',
                    'name': 'edit',
                    'apiGroup': 'rbac.authorization.k8s.io'
                }
            }
            
            edit_result = self._make_request(
                'POST',
                f'/apis/rbac.authorization.k8s.io/v1/namespaces/{project_name}/rolebindings',
                edit_binding
            )
            role_bindings.append(edit_result)

        return role_bindings

    def delete_project(self):
        """Delete OpenShift project"""
        project_name = self.module.params['project_name']
        
        if not self.project_exists(project_name):
            return False, f"Project {project_name} does not exist"

        result = self._make_request('DELETE', f'/api/v1/namespaces/{project_name}')
        return True, result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            api_server=dict(type='str', required=True),
            token=dict(type='str', required=True, no_log=True),
            project_name=dict(type='str', required=True),
            display_name=dict(type='str', required=False),
            description=dict(type='str', required=False),
            keycloak_users=dict(type='list', elements='str', required=False),
            resource_quota=dict(type='dict', required=False),
            limit_range=dict(type='dict', required=False),
            servicenow_request_id=dict(type='str', required=False),
            validate_certs=dict(type='bool', default=True),
            state=dict(type='str', default='present', choices=['present', 'absent'])
        ),
        supports_check_mode=True
    )

    openshift = OpenShiftProjectManager(module)
    state = module.params['state']
    
    if state == 'present':
        changed, result = openshift.create_project()
        module.exit_json(changed=changed, **result if isinstance(result, dict) else {'message': result})
    else:  # state == 'absent'
        changed, result = openshift.delete_project()
        module.exit_json(changed=changed, message=result)


if __name__ == '__main__':
    main()
