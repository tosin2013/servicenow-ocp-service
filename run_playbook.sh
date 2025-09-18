#!/bin/bash
#
# Wrapper script to run ansible-navigator from the execution-environment directory,
# ensuring it picks up the correct configuration and execution environment.
# All arguments passed to this script are forwarded to ansible-navigator.
#

set -euo pipefail

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
