# minimal prompt: dir + git branch/dirty
# ~/.oh-my-zsh/custom/themes/mini.zsh-theme

PROMPT='%F{cyan}%~%f$(git_prompt_info) %F{8}$%f '

ZSH_THEME_GIT_PROMPT_PREFIX=' %F{magenta} '   # branch glyph
ZSH_THEME_GIT_PROMPT_SUFFIX='%f'
ZSH_THEME_GIT_PROMPT_DIRTY='%F{yellow}*'         # * when working tree is dirty
ZSH_THEME_GIT_PROMPT_CLEAN=''
