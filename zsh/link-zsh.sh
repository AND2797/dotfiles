#!/bin/sh
# symlink zsh config from this repo into place.
# run once on a fresh machine after cloning (and after oh-my-zsh is installed).
#
#   ./link-zsh.sh
#
# existing files at the targets are backed up to <target>.bak before linking.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OMZ_THEMES="$HOME/.oh-my-zsh/custom/themes"

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

link "$REPO_DIR/.zshrc" "$HOME/.zshrc"
link "$REPO_DIR/mini.zsh-theme" "$OMZ_THEMES/mini.zsh-theme"
