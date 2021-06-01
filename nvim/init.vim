set exrc
set guicursor=
set relativenumber
set nohlsearch
set hidden
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set noswapfile
set nobackup
set undodir=~/.config/nvim/undodir
set undofile
set incsearch 
set termguicolors
"set scrolloff=8
"set noshowmode
set completeopt=menuone,noinsert,noselect
set signcolumn=yes
set colorcolumn=80
set encoding=UTF-8
set cmdheight=2
set updatetime=50

call plug#begin('~/.config/nvim/plugged')
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'gruvbox-community/gruvbox' 
Plug 'andweeb/presence.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'preservim/nerdtree'
call plug#end()

colorscheme gruvbox
let mapleader = " "
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

nnoremap <leader>nt <cmd>:NERDTree<cr>

"lua << EOF
"require'lspconfig'.pyright.setup{}
"EOF
"
lua << EOF
require'lspconfig'.clangd.setup{}
EOF



