#!/bin/bash
# Hook: Enforce uv for all Python execution
# Intercepts bare python/python3 commands and rewrites to uv run
# Handles: python ..., cd foo && python ..., VAR=x python ..., etc.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check if command contains bare python/python3 invocation anywhere
# Match python/python3 that is NOT already preceded by "uv run"
if echo "$COMMAND" | grep -qE '(^|[;&|] *|&& *|\|\| *)python3?[[:space:]]' && \
   ! echo "$COMMAND" | grep -qE 'uv run python'; then
  # Rewrite all bare python/python3 invocations to uv run python/python3
  # Handles: start of string, after &&, after ;, after ||, after |
  MODIFIED_COMMAND=$(echo "$COMMAND" | sed -E '
    s/(^|([;&|] *|&& *|\|\| *))python3?([[:space:]])/\1uv run python3\3/g
  ')

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
  # Non-python commands or already using uv: pass through unchanged
  echo '{}'
fi
