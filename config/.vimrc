" /home/lxvm/.vimrc
" Last update : Dec 26, 2020

" References
" MIT ./missing-semester course about coding
" https://missing.csail.mit.edu/2020/editors/
" The Vim docs themselves (type :help in normal mode)
" Read these docs to learn Vi
" https://docs.oracle.com/cd/E19253-01/806-7612/6jgfmsvqf/index.html

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Begin external Vim plugins
" Get plugins to save vim sessions
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'
let g:session_autosave = 'yes'
let g:session_autoload = 'no'
" vim and latex plugin
Plugin 'lervag/vimtex'
let g:tex_flavor = 'latex'
let g:vimtex_compiler_latexmk = {
	\ 'build_dir' : '',
	\ 'callback' : 1,
	\ 'continuous' : 1,
	\ 'executable' : 'latexmk',
	\ 'hooks' : [],
	\ 'options' : [
	\   '-verbose',
	\   '-file-line-error',
	\   '-synctex=1',
	\   '-interaction=nonstopmode',
	\   '-shell-escape',
	\ ],
	\}
let g:vimtex_view_general_viewer = 'SumatraPDF'
let g:vimtex_view_general_options
    \ = '-reuse-instance -forward-search @tex @line @pdf'
let g:vimtex_view_general_options_latexmk = '-reuse-instance'
" Use ultisnips plugin for snippets
Plugin 'sirver/ultisnips'
set rtp+=~/.vim/my-snips
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsListSnippets="<c-h>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
let g:UltiSnipsSnippetDirectories=["my-snips"]
" Airline plugin
Plugin 'vim-airline/vim-airline'
let g:airline#extensions#tabline#enabled = 1

" End external Vim plugins
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

" For brief help :h :Plugin<TAB>
" see :h vundle for more details or wiki for FAQ
" End Vundle plugins

" REQUIRES vim-nox the following to work
" enable syntax highlighting
syntax on
" Use 256 colours
 set t_Co=256
" set colorscheme
colorscheme pablo
" Enable spell check (turn on with :set spell)
set spelllang=en
" make it so no more than 79 characters are typed per line 
" because it's easier to read (common in python)
"set textwidth=79 " tmp removed because I waste time fixing long regexp strings
set colorcolumn=80
highlight ColorColumn ctermbg=DarkMagenta

" do not show current mode (i.e. normal, insert) because airline does
set noshowmode
" show previous command at bottom
set showcmd
" always show status line at bottom of window
set laststatus=2 
" show tab bar
set showtabline=2
" show line numbers relative to the cursor
set number
set relativenumber
" show matching sets of parentheses/brackets with highlight
set showmatch

" configure search settings
" enable searching as you type
set incsearch
"highlight search matches
"set hlsearch
" make searches case-insensitive if lower case but sensitive if upper case
set ignorecase
set smartcase

" Let's save undo info!
if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
    call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
set undodir=~/.vim/undo-dir
set undofile

" Define alias for visual block mode
command! Vb normal! <C-v>
