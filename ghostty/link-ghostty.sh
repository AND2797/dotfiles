#!/bin/sh
# symlink ghostty config from this repo into place.
# run once on a fresh machine after cloning.
#
#   ./link-ghostty.sh
#
# existing files at the targets are backed up to <target>.bak before linking.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

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

link "$REPO_DIR/config" "$HOME/.config/ghostty/config"
