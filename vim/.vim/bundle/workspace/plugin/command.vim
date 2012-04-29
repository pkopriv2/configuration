command! -nargs=0 Command call g:Command.Window.Init()

" Setup the options 
let g:Command = {}

" Manages the GrailsCommand buffer.
let g:Command.Window = { 
	\ 'cur_buffer'	: -1,
	\ 'cmd_buffer'	: -1
	\ }

if !exists('g:Command.Window.prompt')
	let g:Command.Window.prompt = 'Command>'
endif

if !exists('g:Command.Window.title')
	let g:Command.Window.title = 'Command Window'
endif

if !exists('g:Command.Window.history')
	let g:Command.Window.history = []
endif

function! g:Command.Window.Init()
	call self.Activate()

	" local autocommands
	augroup GrailsCommand
		autocmd!
		autocmd CursorMovedI <buffer> call g:Command.Window.on_cursor_move()
		autocmd InsertLeave <buffer> call g:Command.Window.on_insert_leave()
	augroup END

	"local mapping
	for [lhs, rhs] in [
		\	[ '<CR>'	, 'g:Command.Window.on_key_exec()'	],
		\	[ '<Down>'	, 'g:Command.Window.on_key_down()'	]
		\ ]

		" hacks to be able to use feedkeys().
		execute printf('inoremap <buffer> <silent> %s <C-r>=%s ? "" : ""<CR>', lhs, rhs)
	endfor

	call setline(1, self.prompt)
	call feedkeys("a", 'n') " startinsert! does not work in InsertLeave handler
endfunction

" Called when the execute key is pressed.
function! g:Command.Window.on_key_exec()
	if pumvisible()
		call feedkeys("\<C-y>\<CR>")
		return
	endif

	" grab the command.
	let cmd = self.RemovePrompt(getline('.'))

	" deactivate the command window.
	call feedkeys("\<Esc>")

	" initialize the history
	let history = [cmd]

	" build the rest of the history
	for item in self.history
		if item != cmd 
			call add(history, item)
		endif 
	endfor

	" now bind the history again
	let self.history = history

	" execute the command
	if exists('g:Command.Exec')
		call g:Command.Exec(cmd)
	endif
endfunction

" Called when the down key is pressed.
function! g:Command.Window.on_key_down()
	if pumvisible()
		call feedkeys("\<Down>", 'n')
		return
	endif

	call feedkeys("\<C-x>\<C-o>", 'n')
endfunction

" Called when the cursor is moved
function! g:Command.Window.on_cursor_move() 
	if !self.ExistsPrompt(getline('.'))
		call setline('.', self.RestorePrompt(getline('.')))
		call feedkeys("\<End>", 'n')
	elseif col('.') <= len(self.prompt)
		" if the cursor is moved before command prompt
		call feedkeys(repeat("\<Right>", len(self.prompt) - col('.') + 1), 'n')
	endif
endfunction

" Called whent he user leaves 'insert' mode.
function! g:Command.Window.on_insert_leave()
	call self.Deactivate()
endfunction

" Determines whether the prompt exists within a given line.
function! g:Command.Window.ExistsPrompt(line)
	return strlen(a:line) >= strlen(self.prompt) && a:line[:strlen(self.prompt) -1] ==# self.prompt
endfunction

" Restores the promp tot he original state. 
function! g:Command.Window.RestorePrompt(line)
	let i = 0
	while i < len(self.prompt) && i < len(a:line) && self.prompt[i] ==# a:line[i]
		let i += 1
	endwhile
	return self.prompt . a:line[i : ]
endfunction

" Returns the line without the prompt
function! g:Command.Window.RemovePrompt(line)
	return a:line[(self.ExistsPrompt(a:line) ? strlen(self.prompt) : 0):]
endfunction

" Sets the local options for the Grails Command Window.
function! g:Command.Window.SetLocalOptions()
	" countermeasure against auto-cd script
	setlocal filetype=command
	setlocal bufhidden=delete
	setlocal buftype=nofile
	setlocal noswapfile
	setlocal nobuflisted
	setlocal modifiable
	setlocal nocursorline	" for highlighting
	setlocal nocursorcolumn " for highlighting
	let &l:omnifunc = 'Complete'
endfunction

function! Complete(findstart, base)
	return g:Command.Window.Complete(a:findstart, a:base)
endfunction

" Opens and activates the Grails Command buffer.
function! g:Command.Window.Activate()
	let self.cur_buffer = bufnr("%")
	let self.cmd_buffer = s:Open1LineBuffer(self.cmd_buffer, self.title)
	
	call self.SetLocalOptions()
	redraw " for 'lazyredraw'
endfunction

" Closes and deactivates the Grails Command buffer.
function! g:Command.Window.Deactivate() 
	execute self.cur_buffer . ' wincmd w'
	execute self.cmd_buffer . ' bdelete'
endfunction

" Provides the complete function
function! g:Command.Window.Complete(findstart, base)
	if a:findstart
		return 0
	elseif	!self.ExistsPrompt(a:base) 
		return []
	endif

	if !empty(self.history)
		call feedkeys("\<Down>")
	endif

	return self.history
endfunction


" Returns a buffer number. Creates new buffer if a:buf_nr is a invalid number
function! s:Open1LineBuffer(buf_nr, buf_name)
	if !bufexists(a:buf_nr)
		topleft 1new
		execute printf('file `=%s`', string(a:buf_name))
	elseif bufwinnr(a:buf_nr) == -1
		topleft 1new
		execute a:buf_nr . 'buffer'
		delete _
	elseif bufwinnr(a:buf_nr) != bufwinnr('%')
		execute bufwinnr(a:buf_nr) . 'wincmd w'
	endif
	return bufnr('%')
endfunction
