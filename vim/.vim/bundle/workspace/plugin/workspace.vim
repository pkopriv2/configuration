" Global options.
let g:workspace = {
	\ 'root' : '/home/pkopriv2/Desktop/Workspace/',
 	\ 'current' : '',
	\ 'spaces' : [
		\ 'Trunk'
	\ ],
	\ 'projects' : [
		\ 'Accounting'
	\]
\ }

" Returns the list of workspaces.
function! GetWorkspaces(A, L, P)
	return g:workspace.spaces
endfunction

" Returns the list of projects
function! GetProjects(A, L, P)
	return g:workspace.projects
endfunction

" Switches vim the input workspace
function! SwitchWorkspace(ws)
	let dir = g:workspace.root . a:ws

	" change the current directory
	execute ":cd " . dir

	" update the nerd tree
	execute ':NERDTree .'
	execute ':NERDTreeClose'
	
	let g:workspace.current = dir
	let g:fuzzy_roots = [dir]
	let g:fuzzy_ignore = '**.svn,*.class,*.jar,**/target/**,**/bin/**,.metadata,.classpath,.settings,*.properties,**/cernprovider-database/**'
	let g:fuzzy_path_display = 'abbr'
	let g:fuzzy_enumerating_limit = 20

	" Refresh the fuzzy finder
	ruby refresh_finder
endfunction

" Easy workspace switching.
command! -nargs=1 -complete=customlist,GetWorkspaces SwitchWorkspace call SwitchWorkspace('<args>')

for space in g:workspace.spaces 
	execute printf("command! -nargs=0 %s call SwitchWorkspace('%s')", space, space)
endfor





" 

let g:Command.Window.prompt = 'Command>'
let g:Command.Window.title = 'Command'
let g:Command.Window.history = [
	\ 'Accounting grails run-app',
	\ 'Accounting grails test-app -unit',
	\ 'Accounting grails test-app -integration'
	\ ]


" Bind the grails command shortcut
nnoremap <silent> <leader>g :Command<CR>
nnoremap <silent> <leader>f :Search<CR>



" Returns the full project name from its shortcut.
function! GetFullProjectName(project)
	return {
		\ 	'Accounting' :  'Accounting',
		\ 	'Domain' : 'Domain'
		\ 	}[a:project]
endfunction

" Returns the url for a given project.
function! GetUrl(project)
	if !exists('s:urls')
		let s:urls = {
		\ 	'Accounting' : 'http://localhost:8080/Accounting',
		\ 	}
	endif

	return s:urls[a:project]
endfunction


" Opens a new instance of chrome at the project root.
function! OpenProjectUrl(project)
	let url = GetUrl(a:project)

	" Handle: Only open an instance of chrome if it is a valid URL.
	if url == ''
		return
	endif

	execute ':!start google-chrome ' . url
endfunction

" Returns the test report locations for each project.
function! GetReportLocation(project) 
	if g:workspace.current 
		return " learn how to throw errors
	endif

	return 'file:///' . g:workspace.current . '/' . GetFullProjectName(a:project) . '/target/test-reports/html/index.html'
endfunction

" Execute the grails command. <project> <cmd>
function! g:Command.Exec(cmd)
	if g:workspace.current == ''
		return
	endif

	" Grab the project
	let parsed = g:Command.ParseCmd(a:cmd)
	
	" Build the command
	let cmd = 'gnome-terminal -x bash -i -c "cd ' . GetFullProjectName(parsed['project']) . '; ' . parsed['command'] . '; read -n1'	

	echo cmd
	
	" If the command is a test-app, open the test report after the command
	" completes.
	if parsed['command'] =~ 'test-app'
		let cmd = cmd . ' ; google-chrome ' . GetReportLocation(parsed['project'])
	endif

	let cmd = cmd . '"'

	" Execute the command
	execute ':! ' . cmd

	" Feed the carriage return to prevent "Press Enter Key" stuff.
	call feedkeys('\<CR>')
endfunction

" Parses the input of the grails command. <project> <cmd>
function! g:Command.ParseCmd(cmd)
	let project = matchstr(a:cmd, '^\w*')
	
	return {
	\ 	'project' : project,
	\ 	'command' : a:cmd[ len(project)+1: ]
	\ 	}
endfunction


function! g:Search.Exec(cmd) 
	if g:workspace.current == ''
		throw 'A workspace must be selected first.'
	endif
	
	" Close the window
	call g:Search.CommandLine.Deactivate()
	 
	" Grab the project
	let parsed = g:Search.ParseCmd(a:cmd)
	
	" Begin building the search command.
	let cmd = 'cmd.exe /c echo Searching for: ' . parsed['command'] . ' & ' 

	" Change the directory, if necessary.
	if has_key(parsed, 'project')
		let cmd = cmd . 'cd ' . GetFullProjectName(parsed['project']) . ' & '
	endif
	
	" Build the search command.
	let cmd = cmd . 'findstr /s /i /n ' . parsed['command'] . ' *.groovy *.proto *.sql *.java'

	" Grab the results	
	let resultsList = split(system(cmd), '\n')
	let results = {}

	for cur in resultsList
		let file = matchstr(cur, '^[^:]*')
		let num = matchstr(cur, '\d\+')
		
		if !has_key(results, file)
			let results[file] = []
		endif

		call add(results[file], num)
	endfor

	" Feed the carriage return to prevent "Press Enter Key" stuff.
	return {
	\ 	'term' : parsed['command'],
	\ 	'results' : results 
	\ 	}
endfunction


" Parses a search string of the form: [project] search_string [flags]
function! g:Search.ParseCmd(cmd)
	let parsed = {}

	" grab the first word in the command.
	let matched = matchstr(a:cmd, '^\w*')
	
	if index(GetProjects('', '', ''), matched) > -1
		let parsed['project'] = matched
		let parsed['command'] = a:cmd[ len(matched)+1 : ]
	else
		let parsed['command'] = a:cmd
	endif

	return parsed
endfunction

"" Removes all the instances of 
"function! CleanApis()
	"if g:workspace.current == ''
		"return
	"endif

	"" Clean out all the projects that import apis
	"for proj in [
			"\ 	'Server',
			"\ 	'Services',
			"\ 	'Buildinator',
			"\ 	'Jobinator'
			"\ ]
	
		"let location = g:workspace.current . '\'. GetFullProjectName(proj) . '\target\ivy2-cache\com.cerner.provider\cernprovider-api'
		"let cmd = 'if exist ' . location . ' rd /q /s ' . location
		
		"execute ':!start cmd.exe /c ' . cmd . ' & exit'
	"endfor

	"" Clean out the local maven repo artifact.
	"let mvnLoc = 'C:\Users\pk020157\.m2\repository\com\cerner\provider\cernprovider-api'
	"execute ':!start cmd.exe /c if exist ' . mvnLoc . ' rd /q /s ' . mvnLoc
"endfunction

"" Does a groovy test-app on the current file.
"function! TestFile()
	"if g:workspace.current == ''
		"throw 'You must select a workspace.'
	"endif

	"" Grab the name of the buffer
	"let name = bufname('%')
	"if name == ''
		"throw 'You must select a file.'
	"endif 

	"echo name
"endfunction

