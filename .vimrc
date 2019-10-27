set encoding=utf8

" =============== COLOR ===============
set t_Co=256
let g:solarized_termcolors=256
syntax enable
set background=light
colorscheme solarized

" =============== Text Format ===============
set tabstop=4               " number of visual spaces per TAB
set shiftwidth=4
set softtabstop=4           " number of spaces in tab when editing
set expandtab               " tabs = spaces
set smarttab
set autoindent
filetype indent on          " load filetype indent files

" =============== General ===============
set nofoldenable            " Stop folding by default
set ignorecase              " Tab complete and search is now fuzzy to case
set smartcase
set number                  " enable line numbers
set showcmd                 " show command in statusline
set cursorline              " highlight line under cursor
set wildmenu                " enable visual autocomplete in commands
set showmatch               " highlight matching breackets etc
set incsearch               " search during entry
set hlsearch                " highlight search matches
set lazyredraw              " stop all the redrawin'
set showmatch				" match braces
set mouse=a					" allow mouse navigation
set foldmethod=syntax       " Auto fold based on syntax. za to toggle a fold.
set backspace=indent,eol,start " Backspace over line endings and inserted stuff.

"More natural split creation
set splitbelow
set splitright

" =============== Key bindings ===============
"move vertically by wrapped line
nnoremap j gj
nnoremap k gk

"Easier movement between splits
nnoremap <C-Right> <C-W><C-L> 
nnoremap <C-Left> <C-W><C-H>
nnoremap <C-Up> <C-W><C-K>
nnoremap <C-Down> <C-W><C-J>

" Move between windows (like NerdTree)
nnoremap <S-Right> <C-W>l 
nnoremap <S-Left> <C-W>h


"Clear highlights after search by pressing return
nnoremap <silent> <CR> :nohlsearch<CR><CR>

" Tab/Shift Tab for indentation
inoremap <S-Tab> <C-d>

" =============== Vim-Plug ===============
call plug#begin('~/.vim/plugged')

Plug 'https://github.com/scrooloose/nerdtree.git'
Plug 'justinmk/vim-sneak'
Plug 'itchyny/lightline.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'https://github.com/airblade/vim-gitgutter.git'
Plug 'rhysd/git-messenger.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'dense-analysis/ale'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'maximbaz/lightline-ale'
Plug 'pangloss/vim-javascript'
Plug 'vim-scripts/AutoComplPop'

call plug#end()

" ======= NerdTree
map <C-t> :NERDTreeToggle<CR>
autocmd vimenter * NERDTree   " Open on Start
autocmd VimEnter * wincmd p   " Move cursor to text window tho
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif " Close if its the last thing open

" ======= Sneak
let g:sneak#s_next = 1 " Press s/S again to go forwards/backwards
let g:sneak#use_ic_scs = 1 " Ignore case

" ======= LightLine
set laststatus=2 " Start it each time
set noshowmode   " Replace built in with lightline
let g:lightline = {
        \   'colorscheme':'solarized',
        \   'active': {
        \       'left': [[ 'mode', 'paste'], ['readonly','filename'],['linter_problems']],
        \       'right': [[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ]] 
        \   },
        \   'component_type': {
        \       'linter_checking': 'left',
        \       'linter_warnings': 'warning',
        \       'linter_errors': 'error',
        \       'linter_ok': 'left',
        \   },
        \   'component_expand': {
        \       'linter_problems': 'LightlineLinterErrors',
        \       'linter_checking': 'lightline#ale#checking',
        \       'linter_warnings': 'lightline#ale#warnings',
        \       'linter_errors': 'lightline#ale#errors',
        \       'linter_ok': 'lightline#ale#ok',
        \   }
        \ }


function! LightlineLinterErrors() abort
    let l:problems = ale#statusline#FirstProblem(bufnr(''), 'error')
    return printf("[%s] %d,%d: %s", problems.linter_name, problems.lnum, problems.col, problems.text)
endfunction

" ======= Prettier
let g:prettier#quickfix_enabled = 0

" ======= ALE
let g:ale_sign_column_always = 1
let g:ale_completion_enabled = 1
let g:ale_fixers = {
    \   'javascript': ['eslint']
    \ }
set omnifunc=ale#completion#OmniFunc
