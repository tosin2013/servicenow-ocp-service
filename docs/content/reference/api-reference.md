# 🔌 API Reference

**Complete reference for all API endpoints used in the ServiceNow-OpenShift integration**

## 🎯 Overview

This reference documents all REST API endpoints, authentication methods, and integration patterns used across the four-tier architecture:

- **ServiceNow APIs**: Table API, OAuth API, REST Message API
- **Keycloak APIs**: Admin API, Authentication API, OIDC endpoints
- **OpenShift APIs**: Kubernetes API, OAuth API, Project API
- **Ansible Automation Platform APIs**: Job Templates, Credentials, Inventory

## 🔐 Authentication Methods

### ServiceNow Authentication

| Method | Usage | Format | Example |
|--------|-------|--------|---------|
| **Basic Auth** | API calls from external systems | `Authorization: Basic <base64>` | `Basic YWRtaW46cGFzc3dvcmQ=` |
| **OAuth 2.0** | Integration with Keycloak | `Authorization: Bearer <token>` | `Bearer eyJhbGciOiJSUzI1NiIs...` |

### Keycloak Authentication

| Method | Usage | Format | Example |
|--------|-------|--------|---------|
| **Admin API** | Administrative operations | `Authorization: Bearer <admin-token>` | `Bearer eyJhbGciOiJSUzI1NiIs...` |
| **OIDC** | User authentication | `Authorization: Bearer <access-token>` | `Bearer eyJhbGciOiJSUzI1NiIs...` |

### OpenShift Authentication

| Method | Usage | Format | Example |
|--------|-------|--------|---------|
| **Service Account Token** | API automation | `Authorization: Bearer <sa-token>` | `Bearer sha256~AbCdEf123...` |
| **OIDC** | User authentication | `Authorization: Bearer <oidc-token>` | `Bearer eyJhbGciOiJSUzI1NiIs...` |

### AAP Authentication

| Method | Usage | Format | Example |
|--------|-------|--------|---------|
| **Bearer Token** | Job template execution | `Authorization: Bearer <aap-token>` | `Bearer MuTGByhq6DNv0TH3fvelWm...` |

## 📊 ServiceNow APIs

### Table API

**Base URL**: `https://{instance}.service-now.com/api/now/table`

#### Get User Information
```http
GET /api/now/table/sys_user?sysparm_limit=1
Authorization: Basic {base64_credentials}
Accept: application/json
```

**Response:**
```json
{
  "result": [
    {
      "sys_id": "6816f79cc0a8016401c5a33be04be441",
      "user_name": "admin",
      "first_name": "System",
      "last_name": "Administrator"
    }
  ]
}
```

#### Create Service Catalog Request
```http
POST /api/now/table/sc_request
Authorization: Basic {base64_credentials}
Content-Type: application/json

{
  "requested_for": "admin",
  "short_description": "OpenShift Project Request",
  "description": "Request for new OpenShift project creation"
}
```

#### Get Catalog Request Items
```http
GET /api/now/table/sc_req_item?sysparm_query=request.number={request_number}
Authorization: Basic {base64_credentials}
Accept: application/json
```

### OAuth Entity API

**Base URL**: `https://{instance}.service-now.com/api/now/table`

#### Create OAuth Application Registry
```http
POST /api/now/table/oauth_entity
Authorization: Basic {base64_credentials}
Content-Type: application/json

{
  "name": "Keycloak SSO Integration",
  "oauth_entity_profile": "keycloak_profile",
  "client_id": "servicenow-client",
  "client_secret": "servicenow-secret-2025",
  "redirect_url": "https://dev295398.service-now.com/oauth_redirect.do",
  "active": "true",
  "type": "oauth_api"
}
```

### Connection & Credential Aliases API

#### Create Connection Alias
```http
POST /api/now/table/sys_alias
Authorization: Basic {base64_credentials}
Content-Type: application/json

{
  "name": "keycloak_connection",
  "connection_url": "https://keycloak-sso.apps.cluster.com",
  "type": "connection",
  "multiple_credentials": "false",
  "active": "true"
}
```

#### Create Credential Profile
```http
POST /api/now/table/sys_auth_profile
Authorization: Basic {base64_credentials}
Content-Type: application/json

{
  "name": "keycloak_credentials",
  "type": "oauth2_authorization_code",
  "oauth_entity_profile": "keycloak_profile",
  "active": "true"
}
```

## 🔑 Keycloak APIs

### Admin API

**Base URL**: `https://{keycloak-host}/auth/admin/realms/{realm}`

#### Get Admin Token
```http
POST /auth/realms/master/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username=admin&password={admin_password}&grant_type=password&client_id=admin-cli
```

**Response:**
```json
{
  "access_token": "JWT_TOKEN_PLACEHOLDER...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer"
}
```

#### Create Realm
```http
POST /auth/admin/realms
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "realm": "servicenow",
  "enabled": true,
  "displayName": "ServiceNow Integration Realm"
}
```

#### Create Client
```http
POST /auth/admin/realms/servicenow/clients
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "clientId": "servicenow-client",
  "enabled": true,
  "protocol": "openid-connect",
  "publicClient": false,
  "redirectUris": ["https://dev295398.service-now.com/oauth_redirect.do"],
  "webOrigins": ["https://dev295398.service-now.com"]
}
```

#### Create User
```http
POST /auth/admin/realms/servicenow/users
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "username": "testuser",
  "enabled": true,
  "firstName": "Test",
  "lastName": "User",
  "email": "testuser@example.com",
  "credentials": [
    {
      "type": "password",
      "value": "password123",
      "temporary": false
    }
  ]
}
```

#### Get Users
```http
GET /auth/admin/realms/servicenow/users
Authorization: Bearer {admin_token}
Accept: application/json
```

#### Get Groups
```http
GET /auth/admin/realms/servicenow/groups
Authorization: Bearer {admin_token}
Accept: application/json
```

### OIDC Endpoints

#### Well-Known Configuration
```http
GET /auth/realms/servicenow/.well-known/openid_configuration
Accept: application/json
```

**Response:**
```json
{
  "issuer": "https://keycloak-sso.apps.cluster.com/auth/realms/servicenow",
  "authorization_endpoint": "https://keycloak-sso.apps.cluster.com/auth/realms/servicenow/protocol/openid-connect/auth",
  "token_endpoint": "https://keycloak-sso.apps.cluster.com/auth/realms/servicenow/protocol/openid-connect/token",
  "userinfo_endpoint": "https://keycloak-sso.apps.cluster.com/auth/realms/servicenow/protocol/openid-connect/userinfo"
}
```

#### Authorization Endpoint
```http
GET /auth/realms/servicenow/protocol/openid-connect/auth?client_id=servicenow-client&redirect_uri=https://dev295398.service-now.com/oauth_redirect.do&response_type=code&scope=openid
```

#### Token Exchange
```http
POST /auth/realms/servicenow/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&client_id=servicenow-client&client_secret={client_secret}&code={auth_code}&redirect_uri=https://dev295398.service-now.com/oauth_redirect.do
```

## 🚀 OpenShift APIs

### Kubernetes API

**Base URL**: `https://{cluster-api}:6443/api/v1`

#### Get Cluster Version
```http
GET /version
Authorization: Bearer {service_account_token}
Accept: application/json
```

#### Create Project/Namespace
```http
POST /api/v1/namespaces
Authorization: Bearer {service_account_token}
Content-Type: application/json

{
  "apiVersion": "v1",
  "kind": "Namespace",
  "metadata": {
    "name": "my-project",
    "labels": {
      "name": "my-project"
    }
  }
}
```

#### Create RoleBinding
```http
POST /apis/rbac.authorization.k8s.io/v1/namespaces/my-project/rolebindings
Authorization: Bearer {service_account_token}
Content-Type: application/json

{
  "apiVersion": "rbac.authorization.k8s.io/v1",
  "kind": "RoleBinding",
  "metadata": {
    "name": "admin-binding",
    "namespace": "my-project"
  },
  "subjects": [
    {
      "kind": "User",
      "name": "testuser",
      "apiGroup": "rbac.authorization.k8s.io"
    }
  ],
  "roleRef": {
    "kind": "ClusterRole",
    "name": "admin",
    "apiGroup": "rbac.authorization.k8s.io"
  }
}
```

### OpenShift OAuth API

**Base URL**: `https://{cluster-api}:6443/apis/config.openshift.io/v1`

#### Get OAuth Configuration
```http
GET /oauths/cluster
Authorization: Bearer {service_account_token}
Accept: application/json
```

#### Update OAuth Configuration
```http
PATCH /oauths/cluster
Authorization: Bearer {service_account_token}
Content-Type: application/merge-patch+json

{
  "spec": {
    "identityProviders": [
      {
        "name": "keycloak-oidc",
        "type": "OpenID",
        "openID": {
          "clientID": "openshift",
          "clientSecret": {
            "name": "keycloak-client-secret"
          },
          "issuer": "https://keycloak-sso.apps.cluster.com/auth/realms/servicenow"
        }
      }
    ]
  }
}
```

## 🤖 Ansible Automation Platform APIs

### Job Templates API

**Base URL**: `https://{aap-controller}/api/v2`

#### Get Job Templates
```http
GET /api/v2/job_templates/
Authorization: Bearer {aap_token}
Accept: application/json
```

#### Launch Job Template
```http
POST /api/v2/job_templates/9/launch/
Authorization: Bearer {aap_token}
Content-Type: application/json

{
  "extra_vars": {
    "project_name": "my-project",
    "display_name": "My Test Project",
    "environment": "development",
    "servicenow_request_number": "REQ0001234",
    "requestor": "testuser"
  }
}
```

**Response:**
```json
{
  "job": 123,
  "ignored_fields": {},
  "id": 123,
  "type": "job",
  "url": "/api/v2/jobs/123/",
  "related": {
    "created_by": "/api/v2/users/1/",
    "job_template": "/api/v2/job_templates/9/"
  },
  "summary_fields": {
    "job_template": {
      "id": 9,
      "name": "OpenShift Project Creation",
      "description": "Creates OpenShift project with user access"
    }
  }
}
```

#### Get Job Status
```http
GET /api/v2/jobs/123/
Authorization: Bearer {aap_token}
Accept: application/json
```

### Credentials API

#### Get Credentials
```http
GET /api/v2/credentials/
Authorization: Bearer {aap_token}
Accept: application/json
```

#### Create Credential
```http
POST /api/v2/credentials/
Authorization: Bearer {aap_token}
Content-Type: application/json

{
  "name": "OpenShift Service Account",
  "credential_type": 1,
  "inputs": {
    "host": "https://api.cluster.com:6443",
    "bearer_token": "sha256~AbCdEf123..."
  }
}
```

## 🔄 Integration Workflows

### ServiceNow Business Rule API Call

```javascript
// ServiceNow Business Rule implementation
(function executeRule(current, previous) {
    var restMessage = new sn_ws.RESTMessageV2();
    restMessage.setEndpoint('https://aap-controller.apps.cluster.com/api/v2/job_templates/9/launch/');
    restMessage.setHttpMethod('POST');
    restMessage.setRequestHeader('Authorization', 'Bearer ' + getAAPToken());
    restMessage.setRequestHeader('Content-Type', 'application/json');
    
    var payload = {
        extra_vars: {
            project_name: current.variables.project_name,
            display_name: current.variables.display_name,
            environment: current.variables.environment,
            servicenow_request_number: current.request.number,
            requestor: current.request.requested_for.user_name
        }
    };
    
    restMessage.setRequestBody(JSON.stringify(payload));
    var response = restMessage.executeAsync();
})(current, previous);
```

### Shell Script API Helpers

```bash
# ServiceNow API helper function
call_servicenow_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    if [ "$method" = "GET" ]; then
        curl -s -k --user "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
             -X GET \
             -H "Accept: application/json" \
             "${SERVICENOW_URL}${endpoint}"
    else
        curl -s -k --user "${SERVICENOW_USER}:${SERVICENOW_PASS}" \
             -X "$method" \
             -H "Content-Type: application/json" \
             -H "Accept: application/json" \
             -d "$data" \
             "${SERVICENOW_URL}${endpoint}"
    fi
}

# AAP API helper function
call_aap_api() {
    local method="$1"
    local endpoint="$2"
    
    curl -s -k -H "Authorization: Bearer $AAP_TOKEN" \
         -X "$method" \
         "${AAP_URL}${endpoint}"
}
```

## 📋 Common HTTP Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| **200** | OK | Successful request |
| **201** | Created | Resource created successfully |
| **400** | Bad Request | Invalid request format or parameters |
| **401** | Unauthorized | Invalid or missing authentication |
| **403** | Forbidden | Insufficient permissions |
| **404** | Not Found | Resource does not exist |
| **409** | Conflict | Resource already exists |
| **500** | Internal Server Error | Server-side error |

## 🔍 API Testing Examples

### Test ServiceNow Connectivity
```bash
curl -s -k --user "admin:password" \
     -H "Accept: application/json" \
     "https://dev295398.service-now.com/api/now/table/sys_user?sysparm_limit=1"
```

### Test Keycloak Admin API
```bash
# Get admin token
TOKEN=$(curl -s -X POST "https://keycloak-sso.apps.cluster.com/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin&grant_type=password&client_id=admin-cli" | jq -r '.access_token')

# Test API access
curl -s -H "Authorization: Bearer $TOKEN" \
     "https://keycloak-sso.apps.cluster.com/auth/admin/realms/servicenow/users"
```

### Test OpenShift API
```bash
curl -s -k -H "Authorization: Bearer sha256~AbCdEf123..." \
     "https://api.cluster.com:6443/version"
```

### Test AAP API
```bash
curl -s -k -H "Authorization: Bearer MuTGByhq6DNv0TH3fvelWm..." \
     "https://aap-controller.apps.cluster.com/api/v2/ping/"
```

---

**📚 Related Documentation:**
- [Configuration Variables Reference](configuration-variables.md) - Variable definitions
- [Getting Started Guide](../GETTING_STARTED.md) - Setup instructions
- [Keycloak Integration Guide](../KEYCLOAK_INTEGRATION_GUIDE.md) - Identity configuration
