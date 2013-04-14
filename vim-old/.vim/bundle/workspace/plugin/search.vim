command! -nargs=0 Search call g:Search.CommandLine.Init()

" Setup the options 
let g:Search = {}

" Manages the GrailsSearch buffer.
let g:Search.CommandLine = { 
	\ 'cur_buffer'	: -1,
	\ 'cmd_buffer' 	: -1
 	\ }

if !exists('g:Search.CommandLine.prompt')
	let g:Search.CommandLine.prompt = 'Search>'
endif

if !exists('g:Search.CommandLine.title')
	let g:Search.CommandLine.title = 'Search CommandLine'
endif

if !exists('g:Search.CommandLine.history')
	let g:Search.CommandLine.history = []
endif

function! g:Search.CommandLine.Init()
	call self.Activate()

	" local autocommands
	augroup GrailsSearch
		autocmd!
		autocmd CursorMovedI <buffer> call g:Search.CommandLine.on_cursor_move()
		autocmd InsertLeave <buffer> call g:Search.CommandLine.on_insert_leave()
	augroup END

	"local mapping
	for [lhs, rhs] in [
		\   [ '<CR>' 	, 'g:Search.CommandLine.on_key_exec()' 	],
		\   [ '<Down>' 	, 'g:Search.CommandLine.on_key_down()' 	]
		\ ]

		" hacks to be able to use feedkeys().
		execute printf('inoremap <buffer> <silent> %s <C-r>=%s ? "" : ""<CR>', lhs, rhs)
	endfor

	call setline(1, self.prompt)
	call feedkeys("A", 'n') " startinsert! does not work in InsertLeave handler
endfunction

" Called when the execute key is pressed.
function! g:Search.CommandLine.on_key_exec()
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
	if exists('g:Search.Exec')
		" grab the results
		let results = g:Search.Exec(cmd)
		call g:Search.ResultsWindow.Init(results['term'], results['results'])
	endif
endfunction



" Called when the down key is pressed.
function! g:Search.CommandLine.on_key_down()
	if pumvisible()
		call feedkeys("\<Down>", 'n')
		return
	endif

	call feedkeys("\<C-x>\<C-o>", 'n')
endfunction

" Called when the cursor is moved
function! g:Search.CommandLine.on_cursor_move() 
	if !self.ExistsPrompt(getline('.'))
		call setline('.', self.RestorePrompt(getline('.')))
		call feedkeys("\<End>", 'n')
	elseif col('.') <= len(self.prompt)
		" if the cursor is moved before command prompt
		call feedkeys(repeat("\<Right>", len(self.prompt) - col('.') + 1), 'n')
	endif
endfunction

" Called whent he user leaves 'insert' mode.
function! g:Search.CommandLine.on_insert_leave()
	call self.Deactivate()
endfunction

" Determines whether the prompt exists within a given line.
function! g:Search.CommandLine.ExistsPrompt(line)
	return strlen(a:line) >= strlen(self.prompt) && a:line[:strlen(self.prompt) -1] ==# self.prompt
endfunction

" Restores the promp tot he original state. 
function! g:Search.CommandLine.RestorePrompt(line)
	let i = 0
	while i < len(self.prompt) && i < len(a:line) && self.prompt[i] ==# a:line[i]
		let i += 1
	endwhile
	return self.prompt . a:line[i : ]
endfunction

" Returns the line without the prompt
function! g:Search.CommandLine.RemovePrompt(line)
	return a:line[(self.ExistsPrompt(a:line) ? strlen(self.prompt) : 0):]
endfunction

" Sets the local options for the Grails Search CommandLine.
function! g:Search.CommandLine.SetLocalOptions()
	" countermeasure against auto-cd script
	setlocal filetype=command
	setlocal bufhidden=delete
	setlocal buftype=nofile
	setlocal noswapfile
	setlocal nobuflisted
	setlocal modifiable
	setlocal nocursorline   " for highlighting
	setlocal nocursorcolumn " for highlighting
	let &l:omnifunc = 'SearchComplete'
endfunction

function! SearchComplete(findstart, base)
	return g:Search.CommandLine.Complete(a:findstart, a:base)
endfunction

" Opens and activates the Grails Search buffer.
function! g:Search.CommandLine.Activate()
	let self.cur_buffer = bufnr("%")
	let self.cmd_buffer = s:Open1LineBuffer(self.cmd_buffer, self.title)
	
	call self.SetLocalOptions()
	redraw " for 'lazyredraw'
endfunction

" Closes and deactivates the Grails Search buffer.
function! g:Search.CommandLine.Deactivate() 
	execute self.cur_buffer . 'wincmd w'
	execute self.cmd_buffer . 'bdelete'
endfunction

" Provides the complete function
function! g:Search.CommandLine.Complete(findstart, base)
	if a:findstart
		return 0
	elseif  !self.ExistsPrompt(a:base) 
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




" RESULTS WINDOW
let g:Search.ResultsWindow = { 
	\ 'cur_buffer'	: -1,
	\ 'cmd_buffer' 	: -1
 	\ }

if !exists('g:Search.ResultsWindow.title')
	let g:Search.ResultsWindow.title = 'Search Results'
endif

function! OpenSearchResultsWindow()
	call g:Search.ResultsWindow.Reopen()
endfunction

function! g:Search.ResultsWindow.Reopen()
	execute self.cmd_buffer . 'wincmd w'
endfunction

function! g:Search.ResultsWindow.Init(cmd, results)
	call self.Deactivate()
	call self.Activate()
	
	setlocal modifiable 
	call self.Display(a:cmd, a:results)
	setlocal nomodifiable

	execute self.cur_buffer . 'wincmd w'
endfunction

" Called when the execute key is pressed.
"function! g:Search.CommandLine.on_key_exec()
	""local mapping
	"for [lhs, rhs] in [
		"\   [ '<CR>' 	, 'g:Search.ResultsWindow.on_key_exec()' 	],
		"\ ]

		"" hacks to be able to use feedkeys().
		"execute printf('inoremap <buffer> <silent> %s <C-r>=%s ? "" : ""<CR>', lhs, rhs)
	"endfor
"endfunction


function! g:Search.ResultsWindow.Display(cmd, results)
	call setline(1, 'Search Results For: ' . a:cmd)
	call setline(2, '============================')

	let i = 3
	for [key, value] in items(a:results)
		call setline(i, key . ':' . join(value, ','))
		let i += 1
	endfor
endfunction


function! g:Search.ResultsWindow.SetLocalOptions()
	setlocal filetype=results
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	"setlocal nobuflisted
	setlocal nocursorcolumn " for highlighting
	setlocal noequalalways
	setlocal winfixheight
endfunction

" Opens and activates the Grails Search buffer.
function! g:Search.ResultsWindow.Activate()
	let self.cur_buffer = bufnr("%")
	let self.cmd_buffer = s:OpenResultsBuffer(self.cmd_buffer, self.title)
	
	call self.SetLocalOptions()
	redraw " for 'lazyredraw'
endfunction

" Closes and deactivates the Grails Search buffer.
function! g:Search.ResultsWindow.Deactivate() 
	execute self.cur_buffer . ' wincmd w'
	execute self.cmd_buffer . ' bdelete'
endfunction

function! s:OpenResultsBuffer(buf_nr, buf_name)
	if !bufexists(a:buf_nr)
		botright 10new
		execute printf('file `=%s`', string(a:buf_name))
	elseif bufwinnr(a:buf_nr) == -1
		botright 10new
		execute a:buf_nr . 'buffer'
		delete _
	elseif bufwinnr(a:buf_nr) != bufwinnr('%')
		execute bufwinnr(a:buf_nr) . 'wincmd w'
	endif
	return bufnr('%')
endfunction
