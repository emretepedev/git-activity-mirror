#!/bin/bash

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "$ACTIVITY_REPO_DIR/config.sh"

ORIGINAL_HOOKS_PATH=$(git config --global --get core.hooksPath)

cleanup() {
	# restore original hooks path if it exists
	if [ -n "$ORIGINAL_HOOKS_PATH" ]; then
		git config --global core.hooksPath "$ORIGINAL_HOOKS_PATH"
	fi
}

trap cleanup EXIT

# disable global hooks for this commit
git config --global --unset-all core.hooksPath

if [ "$SHOW_INFO_MESSAGES" = true ]; then
	echo "Commiting to sync repository"
fi

GIT_USER_NAME=$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" config --get user.name)
GIT_USER_EMAIL=$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" config --get user.email)

env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" commit -S --allow-empty --allow-empty-message --file /dev/null --author="$GIT_USER_NAME <$GIT_USER_EMAIL>"
