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




" Returns the full project name from its shortcut.
function! GetFullProjectName(project)
	return {
		\ 	'Accounting' :  'Accounting',
		\ 	'Domain' : 'Domain'
		\ 	}[a:project]
endfunction


