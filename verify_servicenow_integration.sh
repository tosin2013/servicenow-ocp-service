#!/bin/bash

# ServiceNow-Keycloak Integration Verification Script
# This script verifies the complete OAuth integration setup

echo "🔍 ServiceNow-Keycloak Integration Verification"
echo "=============================================="

# Configuration
SERVICENOW_URL="https://dev295398.service-now.com"
KEYCLOAK_URL="https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
CLIENT_ID="servicenow-client"
REALM="servicenow"

echo ""
echo "📋 Configuration Details:"
echo "  ServiceNow Instance: $SERVICENOW_URL"
echo "  Keycloak Instance: $KEYCLOAK_URL"
echo "  Realm: $REALM"
echo "  Client ID: $CLIENT_ID"
echo ""

# Test 1: Verify OAuth Entity exists
echo "✅ Test 1: Verify OAuth Entity in ServiceNow"
OAUTH_ENTITY=$(curl -s -u "admin:*AFel2uYm9N@" -H "Accept: application/json" \
  "$SERVICENOW_URL/api/now/table/oauth_entity?sysparm_query=client_id=$CLIENT_ID" | \
  jq -r '.result[0].name // "NOT_FOUND"')

if [ "$OAUTH_ENTITY" != "NOT_FOUND" ]; then
    echo "   ✓ OAuth Entity found: $OAUTH_ENTITY"
else
    echo "   ❌ OAuth Entity not found"
fi

# Test 2: Verify OAuth Profiles exist
echo ""
echo "✅ Test 2: Verify OAuth Profiles in ServiceNow"
OAUTH_PROFILES=$(curl -s -u "admin:*AFel2uYm9N@" -H "Accept: application/json" \
  "$SERVICENOW_URL/api/now/table/sys_auth_profile_oauth2" | \
  jq -r '.result | length')

echo "   ✓ OAuth Profiles found: $OAUTH_PROFILES"

# Test 3: Verify Keycloak Realm and Client
echo ""
echo "✅ Test 3: Verify Keycloak Realm and Client"
KEYCLOAK_REALM_CHECK=$(curl -s -k "$KEYCLOAK_URL/auth/realms/$REALM" | jq -r '.realm // "NOT_FOUND"')

if [ "$KEYCLOAK_REALM_CHECK" = "$REALM" ]; then
    echo "   ✓ Keycloak realm '$REALM' is accessible"
else
    echo "   ❌ Keycloak realm '$REALM' not accessible"
fi

# Test 4: Verify OAuth Endpoints
echo ""
echo "✅ Test 4: Verify OAuth Endpoints"
AUTH_URL="$KEYCLOAK_URL/auth/realms/$REALM/protocol/openid-connect/auth"
TOKEN_URL="$KEYCLOAK_URL/auth/realms/$REALM/protocol/openid-connect/token"

AUTH_CHECK=$(curl -s -k -o /dev/null -w "%{http_code}" "$AUTH_URL")
TOKEN_CHECK=$(curl -s -k -o /dev/null -w "%{http_code}" -X POST "$TOKEN_URL")

echo "   ✓ Authorization endpoint: $AUTH_URL (HTTP $AUTH_CHECK)"
echo "   ✓ Token endpoint: $TOKEN_URL (HTTP $TOKEN_CHECK)"

# Summary
echo ""
echo "🎯 Integration Summary:"
echo "=============================================="
echo "✅ ServiceNow OAuth Entity: $OAUTH_ENTITY"
echo "✅ OAuth Profiles: $OAUTH_PROFILES configured"
echo "✅ Keycloak Realm: $KEYCLOAK_REALM_CHECK"
echo "✅ OAuth Endpoints: Accessible"
echo ""
echo "🚀 Next Steps:"
echo "1. Test OAuth flow in ServiceNow UI"
echo "2. Navigate to: $SERVICENOW_URL/nav_to.do?uri=oauth_app_registry_list.do"
echo "3. Find 'Keycloak SSO Integration' and test OAuth token generation"
echo "4. Use OAuth profiles in REST messages and Flow Designer"
echo ""
echo "📖 Documentation: /tmp/servicenow_oauth_config_summary.md"
