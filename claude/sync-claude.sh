#!/bin/sh
# sync claude config between ~/.claude and this dotfiles repo.
#
#   ./sync-claude.sh pull   copy live config from ~/.claude into the repo (run before commit)
#   ./sync-claude.sh push   copy repo config into ~/.claude (run on a fresh machine)
#
# only the portable files are tracked. machine-local state (history, sessions,
# caches, settings.local.json) is left alone.

set -eu

CLAUDE_DIR="$HOME/.claude"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

FILES="CLAUDE.md settings.json"

usage() {
	echo "usage: $0 {pull|push}" >&2
	exit 1
}

[ $# -eq 1 ] || usage

case "$1" in
	pull)
		for f in $FILES; do
			cp "$CLAUDE_DIR/$f" "$REPO_DIR/$f"
			echo "pulled $f"
		done
		;;
	push)
		for f in $FILES; do
			cp "$REPO_DIR/$f" "$CLAUDE_DIR/$f"
			echo "pushed $f"
		done
		;;
	*)
		usage
		;;
esac
