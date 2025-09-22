#!/bin/bash

# AAP Token Addition Script
# This script helps you securely add the AAP API token to the encrypted vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_FILE="ansible/group_vars/all/vault.yml"
VAULT_PASS_FILE=".vault_pass"
BACKUP_DIR="backups"

echo -e "${BLUE}🔐 AAP Token Addition Script${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if we're in the right directory
if [[ ! -f "$VAULT_FILE" ]]; then
    echo -e "${RED}❌ Error: $VAULT_FILE not found${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}"
    exit 1
fi

if [[ ! -f "$VAULT_PASS_FILE" ]]; then
    echo -e "${RED}❌ Error: $VAULT_PASS_FILE not found${NC}"
    echo -e "${YELLOW}Please ensure the vault password file exists${NC}"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup of current vault
BACKUP_FILE="$BACKUP_DIR/vault_backup_$(date +%Y%m%d_%H%M%S).yml"
echo -e "${YELLOW}📋 Creating backup: $BACKUP_FILE${NC}"
cp "$VAULT_FILE" "$BACKUP_FILE"

# Prompt for AAP token
echo -e "${BLUE}🎯 AAP Token Setup${NC}"
echo -e "${YELLOW}Please follow these steps to get your AAP token:${NC}"
echo
echo "1. Login to AAP Controller:"
echo "   https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
echo
echo "2. Navigate: Access → Users → admin → Tokens"
echo
echo "3. Click 'Add' and configure:"
echo "   - Application Type: Personal access token"
echo "   - Description: ServiceNow Integration Token"
echo "   - Scope: Write"
echo
echo "4. Copy the generated token (shown only once!)"
echo

# Get token from user
echo -e "${BLUE}Enter your AAP API token:${NC}"
read -s AAP_TOKEN
echo

if [[ -z "$AAP_TOKEN" ]]; then
    echo -e "${RED}❌ Error: No token provided${NC}"
    exit 1
fi

# Validate token format (basic check)
if [[ ${#AAP_TOKEN} -lt 20 ]]; then
    echo -e "${YELLOW}⚠️  Warning: Token seems short. AAP tokens are usually longer.${NC}"
    echo -e "${BLUE}Continue anyway? (y/N):${NC}"
    read -n 1 CONTINUE
    echo
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
fi

# Test token before adding to vault
echo -e "${BLUE}🧪 Testing AAP token...${NC}"
AAP_URL="https://ansible-controller-aap.apps.cluster-lgkp4.lgkp4.sandbox1321.opentlc.com"
TEST_RESPONSE=$(curl -s -k -w "%{http_code}" -o /dev/null \
    -H "Authorization: Bearer $AAP_TOKEN" \
    "$AAP_URL/api/v2/job_templates/9/" || echo "000")

if [[ "$TEST_RESPONSE" == "200" ]]; then
    echo -e "${GREEN}✅ Token test successful - Job Template 9 accessible${NC}"
elif [[ "$TEST_RESPONSE" == "401" ]]; then
    echo -e "${RED}❌ Token test failed - Invalid or expired token${NC}"
    echo -e "${YELLOW}Please verify your token and try again${NC}"
    exit 1
elif [[ "$TEST_RESPONSE" == "403" ]]; then
    echo -e "${YELLOW}⚠️  Token valid but insufficient permissions${NC}"
    echo -e "${YELLOW}Ensure token has 'Write' scope${NC}"
    echo -e "${BLUE}Continue anyway? (y/N):${NC}"
    read -n 1 CONTINUE
    echo
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
elif [[ "$TEST_RESPONSE" == "404" ]]; then
    echo -e "${YELLOW}⚠️  Token valid but Job Template 9 not found${NC}"
    echo -e "${YELLOW}This may be expected if template doesn't exist yet${NC}"
    echo -e "${BLUE}Continue anyway? (y/N):${NC}"
    read -n 1 CONTINUE
    echo
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠️  Could not test token (network issue or AAP unavailable)${NC}"
    echo -e "${YELLOW}Response code: $TEST_RESPONSE${NC}"
    echo -e "${BLUE}Continue anyway? (y/N):${NC}"
    read -n 1 CONTINUE
    echo
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
fi

# Create temporary file for editing
TEMP_FILE=$(mktemp)

# Decrypt vault to temp file
echo -e "${BLUE}🔓 Decrypting vault...${NC}"
ansible-vault decrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" --output "$TEMP_FILE"

# Check if token placeholder exists
if grep -q "vault_aap_token.*REPLACE_WITH_AAP_API_TOKEN" "$TEMP_FILE"; then
    echo -e "${BLUE}📝 Updating AAP token in vault...${NC}"
    # Replace the placeholder with actual token
    sed -i "s|vault_aap_token:.*REPLACE_WITH_AAP_API_TOKEN.*|vault_aap_token: \"$AAP_TOKEN\"|" "$TEMP_FILE"
    echo -e "${GREEN}✅ Token placeholder updated${NC}"
elif grep -q "vault_aap_token:" "$TEMP_FILE"; then
    echo -e "${YELLOW}⚠️  vault_aap_token already exists${NC}"
    echo -e "${BLUE}Replace existing token? (y/N):${NC}"
    read -n 1 REPLACE
    echo
    if [[ "$REPLACE" =~ ^[Yy]$ ]]; then
        sed -i "s|vault_aap_token:.*|vault_aap_token: \"$AAP_TOKEN\"|" "$TEMP_FILE"
        echo -e "${GREEN}✅ Existing token replaced${NC}"
    else
        echo -e "${YELLOW}Token not updated${NC}"
        rm "$TEMP_FILE"
        exit 0
    fi
else
    echo -e "${BLUE}📝 Adding AAP token to vault...${NC}"
    # Add token after AAP password line
    sed -i "/vault_aap_password:/a vault_aap_token: \"$AAP_TOKEN\"" "$TEMP_FILE"
    echo -e "${GREEN}✅ Token added to vault${NC}"
fi

# Re-encrypt the vault
echo -e "${BLUE}🔐 Re-encrypting vault...${NC}"
ansible-vault encrypt "$TEMP_FILE" --vault-password-file "$VAULT_PASS_FILE" --output "$VAULT_FILE"

# Clean up temp file
rm "$TEMP_FILE"

echo
echo -e "${GREEN}🎉 AAP Token Successfully Added!${NC}"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Test the integration:"
echo "   ./run_playbook.sh ../ansible/real_aap_integration_test.yml \\"
echo "     -e @../ansible/group_vars/all/vault.yml \\"
echo "     --vault-password-file ../.vault_pass -m stdout"
echo
echo "2. Check the token works:"
echo "   ansible-vault view $VAULT_FILE --vault-password-file $VAULT_PASS_FILE | grep vault_aap_token"
echo
echo -e "${YELLOW}📋 Backup created: $BACKUP_FILE${NC}"
echo -e "${GREEN}🔐 Vault updated and re-encrypted${NC}"
echo
