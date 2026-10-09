#!/bin/bash

SHOW_INFO_MESSAGES=false

# Set in config.local.sh, which is gitignored:
# EXPECTED_USER_EMAIL="public-email@example.com"

# Must stay an `if`: as the last command, a false `[ -f ] && source` would make
# sourcing this file fail and abort the callers under set -e.
if [ -f "$ACTIVITY_REPO_DIR/config.local.sh" ]; then
	# shellcheck source=/dev/null
	source "$ACTIVITY_REPO_DIR/config.local.sh"
fi
