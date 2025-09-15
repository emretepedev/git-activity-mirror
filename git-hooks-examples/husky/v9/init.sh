#!/bin/sh

# show a message when a hook is found (default is false)
SHOW_HOOK_FOUND_MESSAGE=false

HOOK=$(basename "$0")

run_project_hook_if_exists() {
  PROJECT_HOOKS_DIR=$(git config --get core.hooksPath)
  PROJECT_HOOKS_DIR="${PROJECT_HOOKS_DIR%/_}"
  PROJECT_HOOK="${PROJECT_HOOKS_DIR%/}/${HOOK}"

  if [ -f "$PROJECT_HOOK" ]; then
    if [ "$SHOW_HOOK_FOUND_MESSAGE" = true ]; then
      echo "Project hook found for $HOOK"
    fi

    "$PROJECT_HOOK" "$@"

    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      exit $EXIT_CODE
    fi
  fi
}

run_global_hook_if_exists() {
  GLOBAL_HOOKS_DIR=$(git config --global --get core.hooksPath)
  GLOBAL_HOOK="${GLOBAL_HOOKS_DIR%/}/${HOOK}"

  if [ -n "$GLOBAL_HOOKS_DIR" ] && [ -f "$GLOBAL_HOOK" ]; then
    if [ "$SHOW_HOOK_FOUND_MESSAGE" = true ]; then
      echo "Global hook found for $HOOK"
    fi

    "$GLOBAL_HOOK" "$@"

    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      exit $EXIT_CODE
    fi
  fi
}

run_project_hook_if_exists "$@"

run_global_hook_if_exists "$@"

exit 0
