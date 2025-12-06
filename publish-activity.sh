#!/bin/bash

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "$ACTIVITY_REPO_DIR/config.sh"

if [ "$SHOW_INFO_MESSAGES" = true ]; then
	echo "Pushing to sync repository"
fi

env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" push --no-verify
