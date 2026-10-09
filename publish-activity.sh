#!/bin/bash

set -eu

ACTIVITY_REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=/dev/null
source "$ACTIVITY_REPO_DIR/config.sh"

if [ "$SHOW_INFO_MESSAGES" = true ]; then
	echo "Pushing to sync repository"
fi

GIT_ENV_SCRUB=""
for _var in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do
	GIT_ENV_SCRUB="$GIT_ENV_SCRUB -u $_var"
done

# shellcheck disable=SC2086
clean_git() {
	env $GIT_ENV_SCRUB git "$@"
}

BRANCH=$(clean_git -C "$ACTIVITY_REPO_DIR" symbolic-ref --quiet --short HEAD || true)

if [ -z "$BRANCH" ]; then
	echo "Error: $ACTIVITY_REPO_DIR is on a detached HEAD. Not pushing." >&2
	exit 1
fi

REMOTE=$(clean_git -C "$ACTIVITY_REPO_DIR" config --get "branch.$BRANCH.remote" || true)
REMOTE="${REMOTE:-origin}"

# No fallback to `git config user.email` when unset: a hijacked HOME controls
# that value, so the audit would approve whatever was injected.
if [ -n "${EXPECTED_USER_EMAIL:-}" ]; then
	if ! clean_git -C "$ACTIVITY_REPO_DIR" rev-parse --verify --quiet "refs/remotes/$REMOTE/$BRANCH" >/dev/null; then
		echo "Error: no $REMOTE/$BRANCH to compare against, cannot tell which commits are unpublished." >&2
		echo "       Run: git -C $ACTIVITY_REPO_DIR fetch $REMOTE" >&2
		exit 1
	fi

	RANGE="refs/remotes/$REMOTE/$BRANCH..HEAD"

	# NF != 3 is load bearing: Git keeps tabs in idents, so an email with an
	# embedded tab shifts the real committer into $4, past the field comparison.
	FOREIGN=$(clean_git -C "$ACTIVITY_REPO_DIR" log --format='%H%x09%ae%x09%ce' "$RANGE" |
		awk -F'\t' -v ok="$EXPECTED_USER_EMAIL" 'NF != 3 || $2 != ok || $3 != ok')

	if [ -n "$FOREIGN" ]; then
		echo "Error: refusing to push, these commits are not <$EXPECTED_USER_EMAIL>:" >&2
		echo "$FOREIGN" >&2
		exit 1
	fi
fi

# Explicit refspec so push.default or remote.<name>.push cannot add refs the
# audit never looked at.
clean_git -C "$ACTIVITY_REPO_DIR" push --no-verify "$REMOTE" "HEAD:refs/heads/$BRANCH"
