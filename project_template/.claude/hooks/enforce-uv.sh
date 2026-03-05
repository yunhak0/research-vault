#!/bin/bash
# Hook: Enforce uv for all Python execution
# Intercepts bare python/python3 commands and rewrites to uv run

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check if command starts with bare python/python3
if [[ "$COMMAND" =~ ^python3?[[:space:]] ]]; then
  # Rewrite to use uv run
  MODIFIED_COMMAND=$(echo "$COMMAND" | sed -E 's/^(python3?)/uv run \1/')

  jq -n --arg cmd "$MODIFIED_COMMAND" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "Rewritten to use uv run instead of bare python",
      "updatedInput": {
        "command": $cmd
      }
    }
  }'
else
  # Non-python commands: pass through unchanged
  echo '{}'
fi
