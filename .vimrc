"""""""""""""""""""""""""
" Basic features
"""""""""""""""""""""""""
let pathogen_disabled = []
if !has('gui_running')
  call add(g:pathogen_disabled, 'css-color')
endif
call pathogen#infect()

" Display options
syntax on
set cursorline
set number
"set list!                       " Display unprintable characters
"set listchars=tab:▸\ ,trail:•,extends:»,precedes:«
if $TERM =~ '256color'
  set t_Co=256
elseif $TERM =~ '^xterm$'
  set t_Co=256
endif
colorscheme molokai

" Misc
filetype plugin indent on       " Do filetype detection and load custom file plugins and indent files
set hidden                      " Don't abandon buffers moved to the background
set wildmenu                    " Enhanced completion hints in command line
set backspace=eol,start,indent  " Allow backspacing over indent, eol, & start
set complete=.,w,b,u,U,t,i,d    " Do lots of scanning on tab completion
set updatecount=100             " Write swap file to disk every 100 chars
set directory=~/.vim/swap       " Directory to use for the swap file
set diffopt=filler,iwhite       " In diff mode, ignore whitespace changes and align unchanged lines
set scrolloff=3                 " Start scrolling 3 lines before the horizontal window border
set noerrorbells                " Disable error bells
set nostartofline               " Don’t reset cursor to start of line when moving around.
set nowrap               		" Don’t wrap lines by default

" up/down on displayed lines, not real lines. More useful than painful.
noremap k gk
noremap j gj


" Indentation and tabbing
set autoindent smartindent
set smarttab
set tabstop=4
set shiftwidth=4

" viminfo: remember certain things when we exit
" (http://vimdoc.sourceforge.net/htmldoc/usr_21.html)
"   %    : saves and restores the buffer list
"   '100 : marks will be remembered for up to 30 previously edited files
"   /100 : save 100 lines from search history
"   h    : disable hlsearch on start
"   "500 : save up to 500 lines for each register
"   :100 : up to 100 lines of command-line history will be remembered
"   n... : where to save the viminfo files
set viminfo=%100,'100,/100,h,\"500,:100,n~/.vim/viminfo

" Undo
set undolevels=10000
if has("persistent_undo")
  set undodir=~/.vim/undo       " Allow undoes to persist even after a file is closed
  set undofile
endif
nnoremap <C-u> :GundoToggle<CR>

" Search settings
set ignorecase
set smartcase
set nohlsearch
set incsearch
set showmatch

" to_html settings
let html_number_lines = 1
let html_ignore_folding = 1
let html_use_css = 1
"let html_no_pre = 0
"let use_xhtml = 1
let xml_use_xhtml = 1

" Keybindings to native vim features
let mapleader=";"
let localmapleader=","
map <Leader>ss :setlocal spell!<cr>
map <Leader>/ :nohlsearch<cr>
map <M-[> :tprev<CR>
map <M-]> :tnext<CR>
vnoremap . :normal .<CR>
vnoremap @ :normal! @
map <M-j> :bn<cr>
map <M-k> :bp<cr>
map <C-PageDown> :cnext<cr>
map <C-PageUp> :cprev<cr>

nmap <silent> <leader>o :TlistToggle<CR>
nmap <silent> <leader>r :ruby refresh_finder<CR>
nmap <silent> <Leader>b :b#<CR>

vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

au VimEnter * syntax keyword Statement lambda conceal cchar=λ
au VimEnter * hi! link Conceal Statement
au VimEnter * set conceallevel=2


"""""""""""""""""""""""""
" Plugins
"""""""""""""""""""""""""
nnoremap <Leader>n :NERDTreeToggle<cr>
let NERDTreeIgnore=[ '\.pyc$', '\.pyo$', '\.py\$class$', '\.obj$', '\.o$', '\.so$', '\.egg$', '^\.git$' ]
let NERDTreeHighlightCursorline=1
let NERDTreeShowBookmarks=1
let NERDTreeShowFiles=1
let NERDTreeQuitOnOpen = 1

nnoremap <C-y> :YRShow<cr>
let g:yankring_history_dir = '$HOME/.vim'
let g:yankring_manual_clipboard_check = 0

let g:syntastic_enable_signs=1
let g:syntastic_mode_map = { 'mode': 'active',
                           \ 'active_filetypes': [],
                           \ 'passive_filetypes': ['c', 'scss'] }

let g:quickfixsigns_classes=['qfl', 'vcsdiff', 'breakpoints']

let g:Powerline_symbols = 'unicode'
set laststatus=2


"nnoremap <Leader>f :CtrlP<CR>
nmap <silent> <leader>f :FuzzyFinderTextMate<CR>
let g:ctrlp_map = '<c-e>'
let g:ctrlp_custom_ignore = '/\.\|\.o\|\.so'
let g:ctrlp_cmd = 'CtrlPMRU'
let g:ctrlp_open_new_file = 'h'
let g:ctrlp_open_multiple_files = 'h'

noremap <Leader>t= :Tabularize /=<CR>
noremap <Leader>t: :Tabularize /^[^:]*:\zs/l0l1<CR>
noremap <Leader>t> :Tabularize /=><CR>
noremap <Leader>t, :Tabularize /,\zs/l0l1<CR>
noremap <Leader>t{ :Tabularize /{<CR>
noremap <Leader>t\| :Tabularize /\|<CR>


"""""""""""""""""""""""""
" Custom functions
"""""""""""""""""""""""""
:command! -bar -nargs=1 OpenURL :!firefox <args>

"nmap fc :call CleanClose(1)<cr>
"nmap fq :call CleanClose(0)<cr>

function! CleanClose(tosave)
  if (a:tosave == 1)
      w!
  endif
  let todelbufNr = bufnr("%")
  let newbufNr = bufnr("#")
  if ((newbufNr != -1) && (newbufNr != todelbufNr) && buflisted(newbufNr))
      exe "b".newbufNr
  else
      bnext
  endif
  if (bufnr("%") == todelbufNr)
      new
  endif
  exe "bd!".todelbufNr
endfunction


" When opening a file, always jump to the last cursor position
autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \     exe "normal g'\"" |
    \ endif |

" Ruby settings
autocmd FileType ruby,eruby set shiftwidth=2 
autocmd FileType ruby,eruby set tabstop=2 
autocmd FileType ruby,eruby set expandtab

" Tmuxify
let g:tmuxify_pane_split = '-h' 
let g:tmuxify_pane_size = '60' 

" Add support for scheme
 if has("autocmd")
   au BufReadPost *.rkt,*.rktl,*.scheme,*.plt set filetype=scheme
endif

au FileType scheme map <Leader>l :w<CR> :call libtmuxify#pane_send("( load \"".@% . "\" )")<CR>
au FileType scheme map <Leader>r :call libtmuxify#pane_send("racket -il xrepl")<CR>
au FileType scheme :NoMatchParen


let g:paredit_mode = 0 

" Setup Taglist plugin
let Tlist_Auto_Update=1
let Tlist_Close_On_Select=1
let Tlist_Compact_Format=1
"let Tlist_Inc_Winwidth=0 " do not increase window width
let Tlist_Show_One_File=1
"let Tlist_Use_Right_Window=1
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_Sort_Type = "name"

" Always edit file, even when swap file is found
set shortmess+=A

" Toggle paste mode while in insert mode with F12
set pastetoggle=<F12>

au BufNewFile,BufRead *.less set filetype=less

" cscope
if has("cscope")
  set cscopetag " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'

  " check cscope for definition of a symbol before checking ctags: set to 1
  " if you want the reverse search order.
  set csto=0

  " add any cscope database in current directory
  if filereadable("cscope.out")
    cs add cscope.out
  endif

  " show msg when any other cscope db added
  set cscopeverbose
end

nmap <silent> <leader>i :call ToggleIndentGuides()<CR>
function! ToggleIndentGuides()
	if !exists('b:indent_guides')
		let b:indent_guides=0
	endif

	" Handle: turn off indent guides.
	if b:indent_guides
		set listchars=tab:\ \ 
		set nolist
		let b:indent_guides=0
	else
		set listchars=tab:\|\ 
		set list
		let b:indent_guides=1
	endif
endfunction
