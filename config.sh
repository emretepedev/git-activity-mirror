#!/bin/bash

# Defaults. Override any of them in config.local.sh, which is gitignored and
# loaded last; whatever it leaves out keeps the value below.
SHOW_INFO_MESSAGES=false
BLOCK_PUSH_ON_PUBLISH_FAILURE=false
EXPECTED_USER_EMAIL=""

# runner.sh loads this file under sh, so it has to stay POSIX: `.`, not `source`.
# Must stay an `if`: as the last command, a false `[ -f ] && .` would make
# sourcing this file fail and abort the callers under set -e.
if [ -f "$ACTIVITY_REPO_DIR/config.local.sh" ]; then
	# shellcheck source=/dev/null
	. "$ACTIVITY_REPO_DIR/config.local.sh"
fi
