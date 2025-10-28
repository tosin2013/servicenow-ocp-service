#!/bin/bash
# Non-interactive wrapper for simplified workflow

PROJECT_NAME="${1:-test-workflow-$(date +%H%M%S)}"
ENVIRONMENT="${2:-development}"
MODE="${3:-check-first}"

echo "Running workflow non-interactively..."
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Mode: $MODE"
echo ""

# Auto-answer prompts with 'yes' and press Enter
printf "y\n\n" | bash start-simplified-workflow.sh "$PROJECT_NAME" "$ENVIRONMENT" "$MODE" 2>&1
