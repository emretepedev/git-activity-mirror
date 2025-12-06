#!/bin/sh

HOOK_NAME="$1"

UTILS_SCRIPT="$(dirname "$0")/utils.sh"
if [ -f "$UTILS_SCRIPT" ]; then
	# shellcheck source=/dev/null
	. "$UTILS_SCRIPT"
else
	echo "Warning: $UTILS_SCRIPT file not found"
	exit 0
fi

case "$HOOK_NAME" in
"post-commit")
	RECORD_SCRIPT="$(dirname "$0")/record-activity.sh"
	if [ -f "$RECORD_SCRIPT" ]; then
		sh "$RECORD_SCRIPT"
	fi
	;;

"pre-push")
	PUBLISH_SCRIPT="$(dirname "$0")/publish-activity.sh"
	if [ -f "$PUBLISH_SCRIPT" ]; then
		sh "$PUBLISH_SCRIPT"
	fi
	;;

*) ;;
esac
