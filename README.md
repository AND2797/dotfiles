# dotfiles

## what's linked where

- `zsh/` → `~/.zshrc` + omz theme
- `ghostty/` → `~/.config/ghostty/config`
- `claude/` → `~/.claude/CLAUDE.md`, `~/.claude/settings.json`
- `.ideavimrc` → not linked, copy by hand

## new mac

```sh
git clone git@github.com:AND2797/dotfiles.git ~/dotfiles && cd ~/dotfiles
./zsh/link-zsh.sh          # omz first
./ghostty/link-ghostty.sh
./claude/link-claude.sh
```

anything already there gets moved to `.bak`.

## new tool

new folder, drop config in, copy a link script, change the paths at the bottom.

## remember

- don't move this folder, links break
- something not syncing → `ls -l` it. no `->` means the link got clobbered.
  copy that file back here first (it's newer), then rerun the link script
- claude settings.json has the hook pointing at miniconda + `~/.claude/hooks/`,
  neither is in here
