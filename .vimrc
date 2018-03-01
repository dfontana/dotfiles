set encoding=utf8

" =============== COLOR ===============
set t_Co=256
syntax on                   " enable syntax highlighting
colorscheme nord

" =============== Text Format ===============
set tabstop=4               " number of visual spaces per TAB
set shiftwidth=4
set softtabstop=4           " number of spaces in tab when editing
set expandtab               " tabs = spaces
set smarttab
set autoindent
set nolist                  " doesn't mix with softwrapping
set wrap                    " softwrap
set linebreak               " Break characters by breakat definition
set breakat&vim             " default breakat, to prevent override
set conceallevel=2          " Hides format *characters* unless active line
filetype indent on          " load filetype indent files

" =============== Other   ===============
set spell spelllang=en_us   " Spell checking in english US

" =============== General ===============
set nofoldenable            " Turns off autofolding.
set ignorecase              " Turns off case sensitivity
set nosmartcase             " Stops Foo from matching only Foo
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
set foldmethod=syntax       " Auto fold based on syntax definition.
set backspace=indent,eol,start " Fixes obnoxious backspace behavior.. 

" =============== Key bindings ===============
"move vertically by wrapped line
nnoremap j gj
nnoremap k gk

"More natural split creation
set splitbelow
set splitright

"Easier movement between splits
nnoremap <C-Right> <C-W><C-L> 
nnoremap <C-Left> <C-W><C-H>
nnoremap <C-Up> <C-W><C-K>
nnoremap <C-Down> <C-W><C-J>

"Easier movement between buffers (fake tabs, don't tell real vimmers)
nnoremap <C-A-Right> :bnext<CR>
nnoremap <C-A-Left> :bprevious<CR>

"Clear highlights after search by pressing return
nnoremap <silent> <CR> :nohlsearch<CR><CR>

" Plugin Keybindings
map <C-t> :NERDTreeToggle<CR>
map <C-i> :call JsBeautify()<cr>

" =============== VUNDLE ===============
set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'xuyuanp/nerdtree-git-plugin'
Plugin 'bling/vim-airline'
Plugin 'airblade/vim-gitgutter'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'raimondi/delimitmate'
Plugin 'pangloss/vim-javascript'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'edkolev/promptline.vim'
Plugin 'arcticicestudio/nord-vim'
Plugin 'fatih/vim-go'

call vundle#end()
filetype plugin indent on    " required

" =============== CTRLP =================
let g:ctrlp_custom_ignore = 'node_modules\|bower_components\|.DS_Store'

" =============== NERD Commenter ========
" Align line-wise comment delimiters instead of following indentation
let g:NERDDefaultAlign = 'left'

" =============== AIRLINE ===============
"start Airline everytime
set laststatus=2

"Display all buffers when 1 tab is active
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'	
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''
