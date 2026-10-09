#!/bin/sh

HOOK_NAME="$1"

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

# shellcheck source=/dev/null
. "$ACTIVITY_REPO_DIR/config.sh"

get_hostname() {
	_get_hostname_url="$1"
	case "$_get_hostname_url" in
	https://* | http://*)
		_get_hostname_temp_url="${_get_hostname_url#*//}"
		_get_hostname_authority="${_get_hostname_temp_url%%/*}"
		# Remotes can embed credentials (https://user:token@host), and a port
		# may follow the host; neither is part of the name to compare.
		_get_hostname_hostname="${_get_hostname_authority##*@}"
		echo "${_get_hostname_hostname%%:*}"
		return
		;;
	esac
	case "$_get_hostname_url" in
	*@*)
		_get_hostname_temp_url_="${_get_hostname_url#*@}"
		_get_hostname_host_or_alias="${_get_hostname_temp_url_%%:*}"
		_get_hostname_real_hostname=$(ssh -G "$_get_hostname_host_or_alias" 2>/dev/null | awk '/^hostname / { print $2 }')
		if [ -n "$_get_hostname_real_hostname" ]; then
			echo "$_get_hostname_real_hostname"
		else
			echo "$_get_hostname_host_or_alias"
		fi
		return
		;;
	esac
	echo ""
}

GIT_REMOTE_ORIGIN_URL=$(git config --get remote.origin.url)
TARGET_REMOTE_ORIGIN_URL=$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" config --get remote.origin.url)

if [ "$GIT_REMOTE_ORIGIN_URL" = "$TARGET_REMOTE_ORIGIN_URL" ]; then
	exit 0
fi

GIT_USER_EMAIL=$(git config --get user.email)
TARGET_USER_EMAIL=$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE git -C "$ACTIVITY_REPO_DIR" config --get user.email)

# Commits made as the mirror's identity and pushed to the mirror's host already
# count on that profile. A repo without a remote yet will most likely be pushed
# there later, so mirroring it now would count its commits twice.
if [ "$GIT_USER_EMAIL" = "$TARGET_USER_EMAIL" ]; then
	GIT_HOSTNAME=$(get_hostname "$GIT_REMOTE_ORIGIN_URL")
	TARGET_GIT_HOSTNAME=$(get_hostname "$TARGET_REMOTE_ORIGIN_URL")
	if [ -z "$GIT_HOSTNAME" ] || [ "$GIT_HOSTNAME" = "$TARGET_GIT_HOSTNAME" ]; then
		exit 0
	fi
fi

case "$HOOK_NAME" in
post-commit) bash "$ACTIVITY_REPO_DIR/record-activity.sh" ;;
pre-push)
	if ! bash "$ACTIVITY_REPO_DIR/publish-activity.sh"; then
		if [ "$BLOCK_PUSH_ON_PUBLISH_FAILURE" = true ]; then
			exit 1
		fi
		echo "Warning: activity mirror not published, continuing with the push." >&2
	fi
	;;
esac
