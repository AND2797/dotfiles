# dotfiles

## symlinks

- `zsh/` → `~/.zshrc` + omz theme
- `ghostty/` → `~/.config/ghostty/config`
- `claude/` → `~/.claude/CLAUDE.md`, `~/.claude/settings.json`
- `.ideavimrc` → not linked, copy by hand

## new machine (mac or linux)

```sh
git clone git@github.com:AND2797/dotfiles.git ~/dotfiles && cd ~/dotfiles
./install-essential.sh     # fzf, ripgrep, nvim, miniconda (mac needs brew). --dry-run to check first
./zsh/link-zsh.sh          # omz first
./ghostty/link-ghostty.sh
./claude/link-claude.sh
```

anything already there gets moved to `.bak`.

## remember

- don't move this folder, links break
- something not syncing → `ls -l` it. no `->` means the link got clobbered.
  copy that file back here first (it's newer), then rerun the link script
- tool versions are pinned at the top of `install-essential.sh`; bump them there.
  run logs go to `logs/` (gitignored)
