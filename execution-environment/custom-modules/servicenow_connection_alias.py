#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, ServiceNow OpenShift Integration Team
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: servicenow_connection_alias
short_description: Manage ServiceNow Connection & Credential Aliases
description:
  - Creates, updates, or deletes ServiceNow Connection & Credential Aliases
  - Manages OAuth profiles and connection records for external API integrations
  - Supports Keycloak and OpenShift API endpoint configurations
version_added: "1.0.0"
author:
  - ServiceNow OpenShift Integration Team
options:
  instance:
    description:
      - ServiceNow instance URL (e.g., https://dev12345.service-now.com)
    required: true
    type: str
  username:
    description:
      - ServiceNow username for authentication
    required: true
    type: str
  password:
    description:
      - ServiceNow password for authentication
    required: true
    type: str
    no_log: true
  alias_name:
    description:
      - Name of the Connection & Credential Alias
    required: true
    type: str
  alias_type:
    description:
      - Type of the alias (keycloak_api, openshift_api)
    required: true
    choices: ['keycloak_api', 'openshift_api']
    type: str
  endpoint_url:
    description:
      - API endpoint URL for the connection
    required: true
    type: str
  oauth_profile:
    description:
      - OAuth profile configuration for Keycloak connections
    required: false
    type: dict
    suboptions:
      client_id:
        description: OAuth client ID
        type: str
      client_secret:
        description: OAuth client secret
        type: str
        no_log: true
      token_url:
        description: OAuth token endpoint URL
        type: str
  bearer_token:
    description:
      - Bearer token for OpenShift Service Account authentication
    required: false
    type: str
    no_log: true
  state:
    description:
      - Desired state of the connection alias
    default: present
    choices: ['present', 'absent']
    type: str
'''

EXAMPLES = r'''
- name: Create Keycloak API Connection Alias
  servicenow_connection_alias:
    instance: "https://dev12345.service-now.com"
    username: "{{ servicenow_username }}"
    password: "{{ servicenow_password }}"
    alias_name: "keycloak_admin_api"
    alias_type: "keycloak_api"
    endpoint_url: "https://keycloak-sso.apps.cluster.example.com"
    oauth_profile:
      client_id: "servicenow-client"
      client_secret: "{{ vault_keycloak_client_secret }}"
      token_url: "https://keycloak-sso.apps.cluster.example.com/auth/realms/servicenow/protocol/openid-connect/token"
    state: present

- name: Create OpenShift API Connection Alias
  servicenow_connection_alias:
    instance: "https://dev12345.service-now.com"
    username: "{{ servicenow_username }}"
    password: "{{ servicenow_password }}"
    alias_name: "openshift_cluster_api"
    alias_type: "openshift_api"
    endpoint_url: "https://api.cluster.example.com:6443"
    bearer_token: "{{ vault_openshift_service_account_token }}"
    state: present
'''

RETURN = r'''
alias_id:
  description: ServiceNow sys_id of the created/updated connection alias
  returned: success
  type: str
  sample: "a1b2c3d4e5f6789012345678901234567890"
connection_id:
  description: ServiceNow sys_id of the associated connection record
  returned: success
  type: str
  sample: "b2c3d4e5f6789012345678901234567890a1"
changed:
  description: Whether the alias was created or modified
  returned: always
  type: bool
  sample: true
'''

from ansible.module_utils.basic import AnsibleModule
import requests
import json


class ServiceNowConnectionAlias:
    def __init__(self, module):
        self.module = module
        self.instance = module.params['instance']
        self.username = module.params['username']
        self.password = module.params['password']
        self.session = requests.Session()
        self.session.auth = (self.username, self.password)
        self.session.headers.update({
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })

    def _make_request(self, method, endpoint, data=None):
        """Make HTTP request to ServiceNow API"""
        url = f"{self.instance}/api/now/table/{endpoint}"
        try:
            if method == 'GET':
                response = self.session.get(url, params=data)
            elif method == 'POST':
                response = self.session.post(url, json=data)
            elif method == 'PUT':
                response = self.session.put(url, json=data)
            elif method == 'DELETE':
                response = self.session.delete(url)
            
            response.raise_for_status()
            return response.json() if response.content else {}
        except requests.exceptions.RequestException as e:
            self.module.fail_json(msg=f"ServiceNow API request failed: {str(e)}")

    def find_alias(self, alias_name):
        """Find existing connection alias by name"""
        params = {'sysparm_query': f'name={alias_name}'}
        result = self._make_request('GET', 'sys_alias', params)
        return result.get('result', [])

    def create_oauth_profile(self, oauth_config):
        """Create OAuth profile for Keycloak integration"""
        oauth_data = {
            'name': f"OAuth Profile for {oauth_config['client_id']}",
            'client_id': oauth_config['client_id'],
            'client_secret': oauth_config['client_secret'],
            'token_url': oauth_config['token_url'],
            'grant_type': 'client_credentials'
        }
        result = self._make_request('POST', 'oauth_entity_profile', oauth_data)
        return result.get('result', {}).get('sys_id')

    def create_connection_alias(self):
        """Create or update connection alias"""
        alias_name = self.module.params['alias_name']
        alias_type = self.module.params['alias_type']
        endpoint_url = self.module.params['endpoint_url']
        
        # Check if alias already exists
        existing = self.find_alias(alias_name)
        if existing:
            return False, existing[0]['sys_id'], existing[0].get('connection')

        # Create connection record first
        connection_data = {
            'name': f"Connection for {alias_name}",
            'connection_url': endpoint_url,
            'active': 'true'
        }
        
        if alias_type == 'keycloak_api':
            oauth_profile = self.module.params.get('oauth_profile')
            if oauth_profile:
                oauth_profile_id = self.create_oauth_profile(oauth_profile)
                connection_data['oauth_entity_profile'] = oauth_profile_id
        
        connection_result = self._make_request('POST', 'sys_connection', connection_data)
        connection_id = connection_result.get('result', {}).get('sys_id')

        # Create credential record
        credential_data = {
            'name': f"Credential for {alias_name}",
            'active': 'true'
        }
        
        if alias_type == 'openshift_api':
            bearer_token = self.module.params.get('bearer_token')
            if bearer_token:
                credential_data['token'] = bearer_token
                credential_data['type'] = 'bearer_token'
        
        credential_result = self._make_request('POST', 'sys_credential', credential_data)
        credential_id = credential_result.get('result', {}).get('sys_id')

        # Create the alias
        alias_data = {
            'name': alias_name,
            'connection': connection_id,
            'credential': credential_id,
            'active': 'true',
            'type': alias_type
        }
        
        alias_result = self._make_request('POST', 'sys_alias', alias_data)
        alias_id = alias_result.get('result', {}).get('sys_id')
        
        return True, alias_id, connection_id

    def delete_connection_alias(self):
        """Delete connection alias and associated records"""
        alias_name = self.module.params['alias_name']
        existing = self.find_alias(alias_name)
        
        if not existing:
            return False, None, None
        
        alias_id = existing[0]['sys_id']
        connection_id = existing[0].get('connection')
        credential_id = existing[0].get('credential')
        
        # Delete alias
        self._make_request('DELETE', f'sys_alias/{alias_id}')
        
        # Delete associated connection and credential
        if connection_id:
            self._make_request('DELETE', f'sys_connection/{connection_id}')
        if credential_id:
            self._make_request('DELETE', f'sys_credential/{credential_id}')
        
        return True, alias_id, connection_id


def main():
    module = AnsibleModule(
        argument_spec=dict(
            instance=dict(type='str', required=True),
            username=dict(type='str', required=True),
            password=dict(type='str', required=True, no_log=True),
            alias_name=dict(type='str', required=True),
            alias_type=dict(type='str', required=True, choices=['keycloak_api', 'openshift_api']),
            endpoint_url=dict(type='str', required=True),
            oauth_profile=dict(type='dict', required=False),
            bearer_token=dict(type='str', required=False, no_log=True),
            state=dict(type='str', default='present', choices=['present', 'absent'])
        ),
        supports_check_mode=True
    )

    servicenow = ServiceNowConnectionAlias(module)
    state = module.params['state']
    
    if state == 'present':
        changed, alias_id, connection_id = servicenow.create_connection_alias()
        result = dict(
            changed=changed,
            alias_id=alias_id,
            connection_id=connection_id
        )
    else:  # state == 'absent'
        changed, alias_id, connection_id = servicenow.delete_connection_alias()
        result = dict(
            changed=changed,
            alias_id=alias_id,
            connection_id=connection_id
        )
    
    module.exit_json(**result)


if __name__ == '__main__':
    main()
