#!/bin/bash

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "$ACTIVITY_REPO_DIR/config.sh"

if [ "$SHOW_INFO_MESSAGES" = true ]; then
	echo "Commiting to sync repository"
fi

clean_git() {
	env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git "$@"
}

GIT_USER_NAME=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get user.name)
GIT_USER_EMAIL=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get user.email)

clean_git -c core.hooksPath=/dev/null -C "$ACTIVITY_REPO_DIR" \
	commit -S --allow-empty --allow-empty-message --file /dev/null \
	--author="$GIT_USER_NAME <$GIT_USER_EMAIL>" --no-verify
