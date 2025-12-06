#!/bin/sh

hook_name=$1
shift

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd -P)"

global_hook_path="$("$SCRIPT_DIR/should-skip-global-hook.sh" "$hook_name")"
status=$?

if [ "$status" -eq 0 ]; then
  exit 0
fi

sh "$global_hook_path" "$@"
