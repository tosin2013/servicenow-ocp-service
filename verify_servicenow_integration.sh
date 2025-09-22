#!/bin/bash

# ServiceNow Integration Verification Script
# This script verifies the complete ServiceNow integration including catalog forms

echo "🔍 ServiceNow Integration Verification"
echo "======================================"

# Configuration
SERVICENOW_URL="https://dev295398.service-now.com"
KEYCLOAK_URL="https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
CLIENT_ID="servicenow-client"
REALM="servicenow"
# Get credentials from vault
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source vault configuration securely
if [ ! -f "$PROJECT_ROOT/.vault_pass" ]; then
    echo "❌ Error: Vault password file not found at $PROJECT_ROOT/.vault_pass"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/ansible/group_vars/all/vault.yml" ]; then
    echo "❌ Error: Vault file not found at $PROJECT_ROOT/ansible/group_vars/all/vault.yml"
    echo "Please ensure you have completed the vault configuration setup."
    exit 1
fi

# Decrypt vault and source variables
VAULT_TEMP=$(mktemp)
trap "rm -f $VAULT_TEMP" EXIT

if ! ansible-vault view "$PROJECT_ROOT/ansible/group_vars/all/vault.yml" \
    --vault-password-file "$PROJECT_ROOT/.vault_pass" > "$VAULT_TEMP" 2>/dev/null; then
    echo "❌ Error: Failed to decrypt vault file"
    echo "Please check your vault password and file integrity."
    exit 1
fi

# Source the decrypted vault variables
source "$VAULT_TEMP"

# Validate required variables
if [ -z "${vault_servicenow_user:-}" ] || [ -z "${vault_servicenow_password:-}" ]; then
    echo "❌ Error: Required ServiceNow configuration not found in vault"
    echo "Please ensure vault_servicenow_user and vault_servicenow_password are configured."
    exit 1
fi

ADMIN_USER="$vault_servicenow_user"
ADMIN_PASS="$vault_servicenow_password"

echo ""
echo "📋 Configuration Details:"
echo "  ServiceNow Instance: $SERVICENOW_URL"
echo "  Keycloak Instance: $KEYCLOAK_URL"
echo "  Realm: $REALM"
echo "  Client ID: $CLIENT_ID"
echo ""

# Function to make authenticated ServiceNow API calls
servicenow_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"

    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Accept: application/json" -H "Content-Type: application/json" \
             -X "$method" -d "$data" "$SERVICENOW_URL/api/now/table/$endpoint"
    else
        curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Accept: application/json" \
             -X "$method" "$SERVICENOW_URL/api/now/table/$endpoint"
    fi
}

# Test 1: Verify Catalog Items exist
echo "✅ Test 1: Verify ServiceNow Catalog Items"
OPENSHIFT_CATALOG=$(servicenow_api "sc_cat_item?sysparm_query=nameLIKEOpenShift" | jq -r '.result[0] // empty')
USER_CATALOG=$(servicenow_api "sc_cat_item?sysparm_query=nameLIKEKeycloak" | jq -r '.result[0] // empty')

if [ -n "$OPENSHIFT_CATALOG" ]; then
    OPENSHIFT_SYS_ID=$(echo "$OPENSHIFT_CATALOG" | jq -r '.sys_id')
    echo "   ✓ OpenShift Project Request catalog item found: $OPENSHIFT_SYS_ID"
else
    echo "   ❌ OpenShift Project Request catalog item not found"
fi

if [ -n "$USER_CATALOG" ]; then
    USER_SYS_ID=$(echo "$USER_CATALOG" | jq -r '.sys_id')
    echo "   ✓ Keycloak User Account Request catalog item found: $USER_SYS_ID"
else
    echo "   ❌ Keycloak User Account Request catalog item not found"
fi

# Test 2: Verify Form Variables
echo ""
echo "✅ Test 2: Verify Catalog Item Form Variables"

if [ -n "$OPENSHIFT_SYS_ID" ]; then
    OPENSHIFT_VARS=$(servicenow_api "item_option_new?sysparm_query=cat_item=$OPENSHIFT_SYS_ID" | jq -r '.result | length')
    echo "   ✓ OpenShift Project Request form variables: $OPENSHIFT_VARS"

    # List the variables
    servicenow_api "item_option_new?sysparm_query=cat_item=$OPENSHIFT_SYS_ID" | \
        jq -r '.result[] | "     - \(.name): \(.question_text) (\(if .mandatory then "required" else "optional" end))"'
else
    echo "   ❌ Cannot check OpenShift form variables - catalog item not found"
fi

if [ -n "$USER_SYS_ID" ]; then
    USER_VARS=$(servicenow_api "item_option_new?sysparm_query=cat_item=$USER_SYS_ID" | jq -r '.result | length')
    echo "   ✓ User Account Request form variables: $USER_VARS"

    # List the variables
    servicenow_api "item_option_new?sysparm_query=cat_item=$USER_SYS_ID" | \
        jq -r '.result[] | "     - \(.name): \(.question_text) (\(if .mandatory then "required" else "optional" end))"'
else
    echo "   ❌ Cannot check User Account form variables - catalog item not found"
fi

# Test 3: Test Catalog Request Submission
echo ""
echo "✅ Test 3: Test OpenShift Project Request Submission"

if [ -n "$OPENSHIFT_SYS_ID" ]; then
    # Create a test request
    TEST_REQUEST_DATA='{
        "cat_item": "'$OPENSHIFT_SYS_ID'",
        "sysparm_quantity": "1",
        "variables": {
            "project_name": "test-validation-project",
            "display_name": "Test Validation Project",
            "description": "Automated validation test project",
            "requestor": "admin",
            "environment": "development",
            "team": "validation"
        }
    }'

    echo "   🔄 Submitting test OpenShift project request..."
    REQUEST_RESULT=$(servicenow_api "sc_request" "POST" "$TEST_REQUEST_DATA")

    if echo "$REQUEST_RESULT" | jq -e '.result.sys_id' > /dev/null 2>&1; then
        REQUEST_ID=$(echo "$REQUEST_RESULT" | jq -r '.result.sys_id')
        REQUEST_NUMBER=$(echo "$REQUEST_RESULT" | jq -r '.result.number')
        echo "   ✓ Test request created successfully: $REQUEST_NUMBER ($REQUEST_ID)"

        # Check for request items
        sleep 2
        REQUEST_ITEMS=$(servicenow_api "sc_req_item?sysparm_query=request=$REQUEST_ID")
        ITEM_COUNT=$(echo "$REQUEST_ITEMS" | jq -r '.result | length')
        echo "   ✓ Request items created: $ITEM_COUNT"

        if [ "$ITEM_COUNT" -gt 0 ]; then
            ITEM_NUMBER=$(echo "$REQUEST_ITEMS" | jq -r '.result[0].number')
            echo "   ✓ First request item: $ITEM_NUMBER"
        fi
    else
        echo "   ❌ Failed to create test request"
        echo "$REQUEST_RESULT" | jq -r '.error.message // "Unknown error"'
    fi
else
    echo "   ❌ Cannot test request submission - OpenShift catalog item not found"
fi

# Test 4: Verify OAuth Integration
echo ""
echo "✅ Test 4: Verify OAuth Integration"

# Check OAuth Entity
OAUTH_ENTITY=$(servicenow_api "oauth_entity?sysparm_query=client_id=$CLIENT_ID" | jq -r '.result[0].name // "NOT_FOUND"')
if [ "$OAUTH_ENTITY" != "NOT_FOUND" ]; then
    echo "   ✓ OAuth Entity found: $OAUTH_ENTITY"
else
    echo "   ❌ OAuth Entity not found"
fi

# Check Keycloak endpoints
AUTH_URL="$KEYCLOAK_URL/auth/realms/$REALM/protocol/openid-connect/auth"
TOKEN_URL="$KEYCLOAK_URL/auth/realms/$REALM/protocol/openid-connect/token"

AUTH_CHECK=$(curl -s -k -o /dev/null -w "%{http_code}" "$AUTH_URL")
KEYCLOAK_REALM_CHECK=$(curl -s -k "$KEYCLOAK_URL/auth/realms/$REALM" | jq -r '.realm // "NOT_FOUND"')

echo "   ✓ Keycloak realm '$REALM': $KEYCLOAK_REALM_CHECK"
echo "   ✓ Authorization endpoint: HTTP $AUTH_CHECK"

# Test 5: Check Catalog Visibility and Permissions
echo ""
echo "✅ Test 5: Check Catalog Visibility and Permissions"

# Check if catalog items are active and visible
if [ -n "$OPENSHIFT_SYS_ID" ]; then
    CATALOG_ACTIVE=$(echo "$OPENSHIFT_CATALOG" | jq -r '.active')
    CATALOG_CATEGORY=$(echo "$OPENSHIFT_CATALOG" | jq -r '.category.display_value // .category')
    echo "   ✓ OpenShift catalog item active: $CATALOG_ACTIVE"
    echo "   ✓ OpenShift catalog category: $CATALOG_CATEGORY"
fi

# Check user roles and permissions
USER_ROLES=$(servicenow_api "sys_user_has_role?sysparm_query=user.user_name=admin" | jq -r '.result[].role.name' | tr '\n' ', ' | sed 's/,$//')
echo "   ✓ Admin user roles: $USER_ROLES"

# Test catalog access via Service Catalog API
CATALOG_ACCESS_TEST=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Accept: application/json" \
    "$SERVICENOW_URL/api/now/table/sc_catalog" | jq -r '.result | length')
echo "   ✓ Accessible catalogs: $CATALOG_ACCESS_TEST"

# Summary
echo ""
echo "🎯 ServiceNow Integration Summary:"
echo "=============================================="
echo "✅ OpenShift Catalog Item: $([ -n "$OPENSHIFT_SYS_ID" ] && echo "Found ($OPENSHIFT_SYS_ID)" || echo "Not Found")"
echo "✅ User Account Catalog Item: $([ -n "$USER_SYS_ID" ] && echo "Found ($USER_SYS_ID)" || echo "Not Found")"
echo "✅ OpenShift Form Variables: ${OPENSHIFT_VARS:-0}"
echo "✅ User Account Form Variables: ${USER_VARS:-0}"
echo "✅ OAuth Integration: $OAUTH_ENTITY"
echo "✅ Keycloak Realm: $KEYCLOAK_REALM_CHECK"
echo ""
echo "🚀 Testing URLs:"
echo "1. Service Catalog: $SERVICENOW_URL/nav_to.do?uri=catalog_home.do"
echo "2. Flow Designer: $SERVICENOW_URL/nav_to.do?uri=flow_designer.do"
echo "3. OAuth Registry: $SERVICENOW_URL/nav_to.do?uri=oauth_app_registry_list.do"
echo "4. Catalog Items: $SERVICENOW_URL/nav_to.do?uri=sc_cat_item_list.do"
echo ""
echo "🔧 Troubleshooting:"
echo "- If forms not visible: Check catalog item 'active' status and user roles"
echo "- If variables missing: Run the Ansible playbook to recreate form fields"
echo "- If OAuth fails: Verify Keycloak client configuration and ServiceNow OAuth entity"
echo ""
echo "� Test Request Created: ${REQUEST_NUMBER:-None}"
