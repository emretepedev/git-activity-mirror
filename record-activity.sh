#!/bin/bash

set -eu

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "$ACTIVITY_REPO_DIR/config.sh"

if [ "$SHOW_INFO_MESSAGES" = true ]; then
	echo "Commiting to sync repository"
fi

# The environment comes from whichever repo triggered the hook, and GIT_CONFIG_*
# outranks even this repo's own config (identity, gpg.program, sshCommand), so
# every GIT_ variable goes. GNUPGHOME and XDG_CONFIG_HOME stay: signing needs
# them, and the signature check below covers them.
GIT_ENV_SCRUB=""
for _var in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do
	GIT_ENV_SCRUB="$GIT_ENV_SCRUB -u $_var"
done

# shellcheck disable=SC2086
clean_git() {
	env $GIT_ENV_SCRUB git "$@"
}

GIT_USER_NAME=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get user.name || true)
GIT_USER_EMAIL=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get user.email || true)
GIT_SIGNING_KEY=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get user.signingkey || true)

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
	echo "Error: cannot resolve user.name/user.email for $ACTIVITY_REPO_DIR. Not committing." >&2
	exit 1
fi

if [ -n "${EXPECTED_USER_EMAIL:-}" ] && [ "$GIT_USER_EMAIL" != "$EXPECTED_USER_EMAIL" ]; then
	echo "Error: refusing to commit as <$GIT_USER_EMAIL>, expected <$EXPECTED_USER_EMAIL>." >&2
	exit 1
fi

if [ -n "$GIT_SIGNING_KEY" ]; then
	SIGN_FLAG="-S$GIT_SIGNING_KEY"
else
	SIGN_FLAG="-S"
fi

if ! clean_git -C "$ACTIVITY_REPO_DIR" symbolic-ref --quiet HEAD >/dev/null; then
	echo "Error: $ACTIVITY_REPO_DIR is on a detached HEAD. Not committing." >&2
	exit 1
fi

# Hooks from several repos can fire at once. The old-value argument to
# update-ref makes the loser fail instead of clobbering the winner's commit, so
# it rebuilds on the new HEAD rather than dropping its own activity.
for _attempt in 1 2 3 4 5; do
	HEAD_BEFORE=$(clean_git -C "$ACTIVITY_REPO_DIR" rev-parse HEAD)
	HEAD_TREE=$(clean_git -C "$ACTIVITY_REPO_DIR" rev-parse "$HEAD_BEFORE^{tree}")

	# commit-tree, not commit: the object stays unreferenced until the checks below
	# pass. stdin must stay closed, or the empty -F message makes it read one from
	# stdin, blocking in a terminal and publishing whatever was typed.
	# shellcheck disable=SC2086
	NEW_COMMIT=$(env $GIT_ENV_SCRUB \
		GIT_AUTHOR_NAME="$GIT_USER_NAME" GIT_AUTHOR_EMAIL="$GIT_USER_EMAIL" \
		GIT_COMMITTER_NAME="$GIT_USER_NAME" GIT_COMMITTER_EMAIL="$GIT_USER_EMAIL" \
		git -C "$ACTIVITY_REPO_DIR" \
		-c "user.name=$GIT_USER_NAME" -c "user.email=$GIT_USER_EMAIL" \
		commit-tree "$SIGN_FLAG" -p "$HEAD_BEFORE" -F /dev/null "$HEAD_TREE" </dev/null)

	ACTUAL=$(clean_git -C "$ACTIVITY_REPO_DIR" log -1 --format='%ae%x09%ce%x09%G?%x09%GF' "$NEW_COMMIT")
	ACTUAL_AUTHOR=$(printf '%s' "$ACTUAL" | cut -f1)
	ACTUAL_COMMITTER=$(printf '%s' "$ACTUAL" | cut -f2)
	ACTUAL_SIG=$(printf '%s' "$ACTUAL" | cut -f3)
	ACTUAL_KEY=$(printf '%s' "$ACTUAL" | cut -f4)

	if [ "$ACTUAL_AUTHOR" != "$GIT_USER_EMAIL" ] || [ "$ACTUAL_COMMITTER" != "$GIT_USER_EMAIL" ]; then
		echo "Error: identity mismatch, commit not published." >&2
		echo "       expected <$GIT_USER_EMAIL>, got author <$ACTUAL_AUTHOR> committer <$ACTUAL_COMMITTER>." >&2
		exit 1
	fi

	if [ "$ACTUAL_SIG" != "G" ]; then
		echo "Error: commit signature is '$ACTUAL_SIG', not a good signature. Not published." >&2
		exit 1
	fi

	if [ -n "$GIT_SIGNING_KEY" ] && [ "${ACTUAL_KEY%"$GIT_SIGNING_KEY"}" = "$ACTUAL_KEY" ]; then
		echo "Error: signed with $ACTUAL_KEY, expected $GIT_SIGNING_KEY. Not published." >&2
		exit 1
	fi

	if clean_git -C "$ACTIVITY_REPO_DIR" update-ref -m "record-activity" HEAD "$NEW_COMMIT" "$HEAD_BEFORE" 2>/dev/null; then
		exit 0
	fi
done

echo "Error: HEAD of $ACTIVITY_REPO_DIR kept moving, activity not recorded." >&2
exit 1
