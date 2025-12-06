#!/bin/sh

get_hostname() {
	_get_hostname_url="$1"
	case "$_get_hostname_url" in
	https://* | http://*)
		_get_hostname_temp_url="${_get_hostname_url#*//}"
		_get_hostname_hostname="${_get_hostname_temp_url%%/*}"
		echo "$_get_hostname_hostname"
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

if [ "$GIT_USER_EMAIL" = "$TARGET_USER_EMAIL" ]; then
	GIT_HOSTNAME=$(get_hostname "$GIT_REMOTE_ORIGIN_URL")
	TARGET_GIT_HOSTNAME=$(get_hostname "$TARGET_REMOTE_ORIGIN_URL")
	if [ -n "$GIT_HOSTNAME" ] && [ "$GIT_HOSTNAME" = "$TARGET_GIT_HOSTNAME" ]; then
		exit 0
	fi
fi
