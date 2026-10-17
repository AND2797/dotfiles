#!/bin/sh
# symlink claude config from this repo into place.
# run once on a fresh machine after cloning.
#
#   ./link-claude.sh
#
# only the portable files are linked. machine-local state (history, sessions,
# caches, settings.local.json) is left alone.
#
# existing files at the targets are backed up to <target>.bak before linking.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

link() {
	src="$1"
	dst="$2"
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		mv "$dst" "$dst.bak"
		echo "backed up existing $dst -> $dst.bak"
	fi
	mkdir -p "$(dirname "$dst")"
	ln -sfn "$src" "$dst"
	echo "linked $dst -> $src"
}

link "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
