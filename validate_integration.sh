#!/bin/bash

# ServiceNow-OpenShift Integration Validation Script
# This script performs automated health checks on all integration components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KEYCLOAK_URL="https://keycloak-sso.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
SERVICENOW_URL="https://dev295398.service-now.com"
OPENSHIFT_CONSOLE="https://console-openshift-console.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
AAP_URL="https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  ServiceNow-OpenShift Integration Validator${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_failure() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test 1: OpenShift Cluster Connectivity
test_openshift_cluster() {
    print_test "OpenShift Cluster Connectivity"
    
    if oc whoami &>/dev/null; then
        CURRENT_USER=$(oc whoami)
        print_success "Connected to OpenShift as: $CURRENT_USER"
    else
        print_failure "Cannot connect to OpenShift cluster"
        return 1
    fi
    
    # Check critical namespaces
    for ns in sso aap openshift-gitops; do
        if oc get namespace $ns &>/dev/null; then
            print_success "Namespace '$ns' exists"
        else
            print_failure "Namespace '$ns' missing"
        fi
    done
}

# Test 2: Keycloak/RH-SSO Status
test_keycloak_status() {
    print_test "Keycloak/RH-SSO Status"
    
    # Check Keycloak pods
    if oc get pods -n sso | grep -q "keycloak.*Running"; then
        print_success "Keycloak pods are running"
    else
        print_failure "Keycloak pods not running properly"
    fi
    
    # Test Keycloak URL accessibility
    if curl -k -s --connect-timeout 10 "$KEYCLOAK_URL/auth" | grep -q "Keycloak"; then
        print_success "Keycloak web interface accessible"
    else
        print_failure "Keycloak web interface not accessible"
    fi
    
    # Test ServiceNow realm
    if curl -k -s --connect-timeout 10 "$KEYCLOAK_URL/auth/realms/servicenow/.well-known/openid_configuration" | grep -q "issuer"; then
        print_success "ServiceNow realm configured"
    else
        print_failure "ServiceNow realm not accessible"
    fi
}

# Test 3: ServiceNow Connectivity
test_servicenow_connectivity() {
    print_test "ServiceNow Instance Connectivity"
    
    # Test ServiceNow API with credentials from vault
    if [ -f ".vault_pass" ] && [ -f "ansible/group_vars/all/vault.yml" ]; then
        # Try to get ServiceNow password from vault
        SERVICENOW_PASS=$(ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass 2>/dev/null | grep "vault_servicenow_password:" | cut -d'"' -f2)
        
        if [ -n "$SERVICENOW_PASS" ]; then
            if curl -k -s -u "admin:$SERVICENOW_PASS" "$SERVICENOW_URL/api/now/table/sys_user?sysparm_limit=1" | grep -q "result"; then
                print_success "ServiceNow API accessible with credentials"
            else
                print_failure "ServiceNow API authentication failed"
            fi
        else
            print_failure "Cannot retrieve ServiceNow password from vault"
        fi
    else
        print_failure "Vault files not found - cannot test ServiceNow credentials"
    fi
    
    # Test basic connectivity
    if curl -k -s --connect-timeout 10 "$SERVICENOW_URL" | grep -q "ServiceNow"; then
        print_success "ServiceNow instance accessible"
    else
        print_failure "ServiceNow instance not accessible"
    fi
}

# Test 4: OpenShift OAuth Configuration
test_openshift_oauth() {
    print_test "OpenShift OAuth Configuration"
    
    # Check if OIDC identity provider is configured
    if oc get oauth cluster -o yaml | grep -q "keycloak-oidc"; then
        print_success "Keycloak OIDC identity provider configured"
    else
        print_failure "Keycloak OIDC identity provider not found"
    fi
    
    # Check OAuth pods
    if oc get pods -n openshift-authentication | grep -q "oauth-openshift.*Running"; then
        print_success "OAuth authentication pods running"
    else
        print_failure "OAuth authentication pods not running"
    fi
    
    # Check for OIDC client secret
    if oc get secret oidc-client-secret -n openshift-config &>/dev/null; then
        print_success "OIDC client secret exists"
    else
        print_failure "OIDC client secret missing"
    fi
}

# Test 5: AAP Status
test_aap_status() {
    print_test "Ansible Automation Platform Status"
    
    # Check AAP pods
    if oc get pods -n aap | grep -q "ansible-controller.*Running"; then
        print_success "AAP Controller pods running"
    else
        print_failure "AAP Controller pods not running"
    fi
    
    # Test AAP URL accessibility
    if curl -k -s --connect-timeout 10 "$AAP_URL" | grep -q -i "automation"; then
        print_success "AAP Controller web interface accessible"
    else
        print_failure "AAP Controller web interface not accessible"
    fi
}

# Test 6: RBAC Group Mappings
test_rbac_mappings() {
    print_test "RBAC Group Mappings"
    
    # Check for OIDC group bindings
    local group_bindings=("oidc-cluster-admins" "oidc-developers" "oidc-viewers" "oidc-servicenow-users")
    
    for binding in "${group_bindings[@]}"; do
        if oc get clusterrolebinding "$binding" &>/dev/null; then
            print_success "ClusterRoleBinding '$binding' exists"
        else
            print_failure "ClusterRoleBinding '$binding' missing"
        fi
    done
}

# Test 7: Integration Endpoints
test_integration_endpoints() {
    print_test "Integration Endpoints"
    
    # Test OpenShift console
    if curl -k -s --connect-timeout 10 "$OPENSHIFT_CONSOLE" | grep -q -i "openshift"; then
        print_success "OpenShift Console accessible"
    else
        print_failure "OpenShift Console not accessible"
    fi
    
    # Test Keycloak admin console
    if curl -k -s --connect-timeout 10 "$KEYCLOAK_URL/auth/admin" | grep -q -i "keycloak"; then
        print_success "Keycloak Admin Console accessible"
    else
        print_failure "Keycloak Admin Console not accessible"
    fi
}

# Generate summary report
generate_summary() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}           VALIDATION SUMMARY${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo -e "Success Rate: $SUCCESS_RATE%"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Integration is ready for use.${NC}"
        echo ""
        echo -e "${BLUE}Next Steps:${NC}"
        echo "1. Test OpenShift OIDC login: $OPENSHIFT_CONSOLE"
        echo "2. Verify ServiceNow OAuth profiles"
        echo "3. Configure Flow Designer workflows"
        echo "4. Run end-to-end integration tests"
    else
        echo -e "${RED}⚠️  Some tests failed. Please review the issues above.${NC}"
        echo ""
        echo -e "${BLUE}Troubleshooting:${NC}"
        echo "1. Check the INTEGRATION_TESTING_GUIDE.md for detailed steps"
        echo "2. Verify all credentials are correct"
        echo "3. Ensure all playbooks have been run successfully"
        echo "4. Check system logs for specific error messages"
    fi
    
    echo ""
    echo -e "${BLUE}Access URLs:${NC}"
    echo "• Keycloak Admin: $KEYCLOAK_URL/auth/admin"
    echo "• ServiceNow: $SERVICENOW_URL"
    echo "• OpenShift Console: $OPENSHIFT_CONSOLE"
    echo "• AAP Controller: $AAP_URL"
    echo ""
}

# Main execution
main() {
    print_header
    
    print_info "Starting integration validation..."
    echo ""
    
    test_openshift_cluster
    echo ""
    
    test_keycloak_status
    echo ""
    
    test_servicenow_connectivity
    echo ""
    
    test_openshift_oauth
    echo ""
    
    test_aap_status
    echo ""
    
    test_rbac_mappings
    echo ""
    
    test_integration_endpoints
    
    generate_summary
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
