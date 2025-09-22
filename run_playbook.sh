#!/bin/bash
#
# Script Name: run_playbook.sh
# Purpose: Wrapper script to execute Ansible playbooks using ansible-navigator with ServiceNow execution environment
# Author: ServiceNow-OpenShift Integration Project
# Last Modified: 2025-09-22
# Documentation: See docs/content/reference/shell-scripts-reference.md
#
# Usage: ./run_playbook.sh <playbook-path> [ansible-navigator-options]
# 
# Examples:
#   ./run_playbook.sh ansible/preflight_checks.yml -e @ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
#   ./run_playbook.sh ansible/playbook.yml -m stdout --vault-password-file .vault_pass
#
# Prerequisites:
#   - ansible-navigator.yml must exist in execution-environment/ directory
#   - ServiceNow execution environment container must be available
#   - Must be run from project root directory
#

set -euo pipefail

# Usage function
usage() {
    echo "Usage: $0 <playbook-path> [ansible-navigator-options]"
    echo ""
    echo "Execute Ansible playbooks using ansible-navigator with ServiceNow execution environment"
    echo ""
    echo "Arguments:"
    echo "  <playbook-path>               Path to Ansible playbook (relative to project root)"
    echo "  [ansible-navigator-options]   Additional ansible-navigator options"
    echo ""
    echo "Examples:"
    echo "  $0 ansible/preflight_checks.yml --vault-password-file .vault_pass"
    echo "  $0 ansible/playbook.yml -e @ansible/group_vars/all/vault.yml -m stdout"
    echo "  $0 ansible/configure_aap.yml --vault-password-file .vault_pass"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "For detailed documentation, see: docs/content/reference/shell-scripts-reference.md"
    exit 1
}

# Check for help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

# Validate arguments
if [[ $# -eq 0 ]]; then
    echo "Error: Playbook path is required" >&2
    usage
fi

# The script should be run from the project root.
PROJECT_ROOT=$(pwd)
EE_DIR="${PROJECT_ROOT}/execution-environment"

# Verify that the configuration file exists where we expect it.
if [ ! -f "${EE_DIR}/ansible-navigator.yml" ]; then
    echo "Error: ansible-navigator.yml not found in ${EE_DIR}" >&2
    exit 1
fi

# Change to execution-environment directory for ansible-navigator context
cd "${EE_DIR}"

# Execute ansible-navigator, passing all script arguments to it.
# The playbook path should be relative to the project root.
ansible-navigator run "${@}" --eei quay.io/takinosh/servicenow-ocp-ee:785b6cec231f96ae1400f6204e7f831ebb67f38a --pull-policy never

# Capture and exit with the code from the ansible-navigator command.
EXIT_CODE=$?
echo "==> ansible-navigator finished with exit code: ${EXIT_CODE}"
exit ${EXIT_CODE}
