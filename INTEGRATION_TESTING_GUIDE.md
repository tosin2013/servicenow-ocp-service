# ServiceNow-OpenShift Integration Testing Guide

## 🎯 Overview

This guide provides step-by-step instructions to validate the complete ServiceNow-OpenShift integration system. The integration includes:

- **Keycloak/RH-SSO**: Identity provider with ServiceNow realm
- **OpenShift OIDC**: Single Sign-On authentication via Keycloak
- **ServiceNow OAuth**: OAuth profiles and connection aliases
- **Ansible Automation Platform**: Ready for workflow automation

## 🔐 Test Credentials

| Service | URL | Username | Password | Notes |
|---------|-----|----------|----------|-------|
| **Keycloak Admin** | https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/auth/admin | `admin` | `Y4MMa87hbD1O0Q==` | Admin console |
| **ServiceNow** | https://dev295398.service-now.com | `admin` | `*AFel2uYm9N@` | ServiceNow instance |
| **OpenShift Console** | https://console-openshift-console.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com | `kube:admin` | Token-based | Admin access |
| **AAP Controller** | https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com | `admin` | `xb3QI0s6tRmiQoscS8BbP3nQO6kjVxii` | Automation platform |
| **Test OIDC User** | OpenShift Console | `oidc-demo-user` | `DemoPassword123!` | Demo user via Keycloak |

## 🧪 Test Scenarios

### Test 1: Keycloak Configuration Validation

**Objective**: Verify Keycloak is properly configured with ServiceNow realm and clients.

**Steps**:
1. Navigate to Keycloak Admin Console: https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/auth/admin
2. Login with: `admin` / `Y4MMa87hbD1O0Q==`
3. Verify **ServiceNow Realm** exists:
   - Click on realm dropdown (top-left)
   - Should see "servicenow" realm
4. Switch to ServiceNow realm and verify clients:
   - **servicenow-client**: OAuth client for ServiceNow integration
   - **openshift**: OIDC client for OpenShift authentication

**Expected Results**:
- ✅ ServiceNow realm exists and is accessible
- ✅ Both OAuth clients are configured
- ✅ Client secrets are set: `servicenow-secret-2025` for ServiceNow client

**Troubleshooting**:
- If realm doesn't exist, re-run: `./run_playbook.sh ansible/playbook.yml`
- Check Keycloak pod status: `oc get pods -n sso`

---

### Test 2: OpenShift OIDC Authentication

**Objective**: Verify users can authenticate to OpenShift using Keycloak SSO.

**Steps**:
1. Navigate to OpenShift Console: https://console-openshift-console.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com
2. You should see multiple login options including **"Keycloak SSO"**
3. Click on **"Keycloak SSO"**
4. Login with test user: `oidc-demo-user` / `DemoPassword123!`
5. Verify successful login and user permissions

**Expected Results**:
- ✅ Keycloak SSO option appears on login page
- ✅ Successful authentication with test user
- ✅ User has `edit` permissions (developers group)
- ✅ Can access projects and create resources

**Troubleshooting**:
- If OIDC option missing, check OAuth configuration: `oc get oauth cluster -o yaml`
- Verify OIDC pods: `oc get pods -n openshift-authentication`
- Re-run OIDC playbook: `./run_playbook.sh ansible/openshift_oidc_playbook.yml`

---

### Test 3: ServiceNow OAuth Configuration

**Objective**: Verify ServiceNow OAuth profiles and connection aliases are configured.

**Steps**:
1. Login to ServiceNow: https://dev295398.service-now.com
2. Use credentials: `admin` / `*AFel2uYm9N@`
3. Navigate to **System OAuth > OAuth Entity Profiles**
4. Verify **keycloak_profile** exists
5. Navigate to **System OAuth > OAuth 2.0 Authentication Profiles**
6. Verify **Keycloak OAuth2 Profile** exists
7. Check **Connection & Credential Aliases**:
   - Navigate to **System Web Services > Connection Aliases**
   - Verify: `keycloak_connection`, `openshift_connection`

**Expected Results**:
- ✅ OAuth Entity Profile: `keycloak_profile` exists
- ✅ OAuth2 Auth Profile: `Keycloak OAuth2 Profile` exists
- ✅ Connection aliases configured for both Keycloak and OpenShift
- ✅ Credential aliases properly set up

**Troubleshooting**:
- If profiles missing, re-run: `./run_playbook.sh ansible/oauth_integration_playbook.yml`
- Check ServiceNow system logs for OAuth errors
- Verify network connectivity to Keycloak from ServiceNow

---

### Test 4: End-to-End OAuth Flow Test

**Objective**: Test the complete OAuth flow between ServiceNow and Keycloak.

**Steps**:
1. In ServiceNow, navigate to **System Web Services > REST Messages**
2. Create a test REST message with:
   - **Name**: `Keycloak Test`
   - **Endpoint**: `https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/auth/realms/servicenow/protocol/openid-connect/userinfo`
   - **Authentication**: Use `Keycloak OAuth2 Profile`
3. Test the connection
4. Verify successful OAuth token exchange

**Expected Results**:
- ✅ OAuth authentication succeeds
- ✅ Token is obtained from Keycloak
- ✅ API call returns user information
- ✅ No authentication errors in logs

---

### Test 5: Ansible Automation Platform Validation

**Objective**: Verify AAP is accessible and ready for automation workflows.

**Steps**:
1. Navigate to AAP Controller: https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com
2. Login with: `admin` / `xb3QI0s6tRmiQoscS8BbP3nQO6kjVxii`
3. Verify dashboard loads successfully
4. Check **Credentials** section for:
   - OpenShift API credentials
   - ServiceNow credentials
   - Keycloak credentials
5. Verify **Projects** and **Job Templates** are ready

**Expected Results**:
- ✅ AAP Controller accessible
- ✅ Dashboard shows healthy status
- ✅ Credentials configured for all services
- ✅ Ready for workflow automation

---

## 🔍 Integration Health Check

### Quick Validation Commands

Run these commands to verify system health:

```bash
# Check OpenShift cluster status
oc get nodes
oc get pods -n sso
oc get pods -n aap

# Verify OAuth configuration
oc get oauth cluster -o yaml | grep -A 10 identityProviders

# Test Keycloak connectivity
curl -k https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com/auth/realms/servicenow/.well-known/openid_configuration

# Test ServiceNow API
curl -k -u "admin:*AFel2uYm9N@" "https://dev295398.service-now.com/api/now/table/sys_user?sysparm_limit=1"
```

### Expected Health Indicators

| Component | Health Check | Expected Result |
|-----------|--------------|-----------------|
| **Keycloak** | Pod status | `Running` |
| **ServiceNow** | API response | `200 OK` |
| **OpenShift OAuth** | OIDC provider | `keycloak-oidc` configured |
| **AAP** | Controller status | Dashboard accessible |

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

**Issue**: Keycloak SSO option not appearing on OpenShift login
- **Solution**: Re-run `./run_playbook.sh ansible/openshift_oidc_playbook.yml`
- **Check**: `oc get oauth cluster -o yaml`

**Issue**: ServiceNow OAuth profiles missing
- **Solution**: Verify ServiceNow credentials and re-run OAuth integration
- **Check**: ServiceNow system logs for authentication errors

**Issue**: OIDC authentication fails
- **Solution**: Verify Keycloak realm configuration and client settings
- **Check**: Keycloak admin console for error logs

**Issue**: AAP not accessible
- **Solution**: Check pod status and route configuration
- **Check**: `oc get pods -n aap` and `oc get routes -n aap`

## 📊 Success Criteria

The integration is considered successful when:

- ✅ All 5 test scenarios pass
- ✅ Users can authenticate to OpenShift via Keycloak
- ✅ ServiceNow OAuth profiles are configured
- ✅ Connection aliases work properly
- ✅ AAP is ready for automation workflows

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review system logs for specific error messages
3. Verify all credentials are correct and current
4. Ensure network connectivity between all components

---

**Integration Status**: ✅ Ready for Production Testing
**Last Updated**: September 17, 2025
**Version**: 1.0
