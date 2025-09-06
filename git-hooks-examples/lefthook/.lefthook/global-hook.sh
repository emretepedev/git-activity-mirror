#!/bin/sh

hook_name=$1

project_hooks_dir="$(git config --get core.hooksPath 2>/dev/null || true)"
global_hooks_dir="$(git config --global --get core.hooksPath 2>/dev/null || true)"

if [ "$project_hooks_dir" = "$global_hooks_dir" ]; then
  exit 0
fi

hook_script="${global_hooks_dir%/}/$hook_name"
if [ ! -f "$hook_script" ]; then
  exit 0
fi

"$hook_script"
