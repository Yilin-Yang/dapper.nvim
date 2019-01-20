" BRIEF:  For cribbing functionality and configurations from VSCode.

" BRIEF: Search upwards from the current directory to find a `.vscode` folder.
" DETAILS:  Throws an `ERROR(NotFound)` if none could be found.
" RETURNS:  (v:t_string)  The abs. filepath of the first found folder
"     containing a `.vscode` folder.
function! dapper#vscode#FindWorkspace(pwd) abort
  let l:search_dir = a:pwd
  let l:fpath = ''
  while empty(l:fpath)
    let l:contents = dapper#helpers#ls(l:search_dir)
    if index(l:contents, '.vscode') !=# -1
      let l:fpath = l:search_dir
    else
      let l:search_dir = split(l:search_dir, '/[^/]*$')[0] " trim current folder
      if match(l:search_dir, '^\%(\s\|\r\|\n\)*$') ==# 0
        " entire search path is empty or whitespace
        let l:err_text = 'Could not find .vscode folder'
        call g:dapper_debug_logger.notifyReport(
            \ 'error',
            \ l:err_text,
            \ '(dapper#vscode#FindWorkspace) Searched from: '.a:pwd)
        throw 'ERROR(NotFound) '.l:err_text
      endif
    endif
  endwhile
  return l:fpath
endfunction

" RETURNS:  (v:t_dict)  What s:vscode_variables would be, given a certain
"     workspace and file.
" PARAM:  workspace   (v:t_string)  The absolute path to the workspace folder.
" PARAM:  cwd   (v:t_string)  The absolute path to the current working directory.
" PARAM:  file  (v:t_string)  The absolute path of the file currently open.
" PARAM:  curpos  (v:t_list)  The position of the cursor, as returned by
"     `getcurpos()`.
" PARAM:  selection (v:t_string)  The current visual selection.
function! dapper#vscode#VSCodeVariablesFrom(
    \ workspace, cwd, file, curpos, selection) abort
  if type(a:workspace) !=# v:t_string
      \ || type(a:cwd) !=# v:t_string
      \ || type(a:file) !=# v:t_string
      \ || type(a:selection) !=# v:t_string
    throw 'ERROR(WrongType) Should be strings: '
        \ . dapper#helpers#StrDump(a:workspace) . ', '
        \ . dapper#helpers#StrDump(a:cwd)
        \ . dapper#helpers#StrDump(a:file)
        \ . dapper#helpers#StrDump(a:selection)
  endif
  if type(a:curpos) !=# v:t_list
    throw 'ERROR(WrongType) Should be list: '
        \ . dapper#helpers#StrDump(a:curpos)
  endif
  let l:file_basename = split(a:file, '^.*/')[0]
  let l:file_basename_split_on_period = split(l:file_basename, '\.')
  let l:file_extname = ''
  if len(l:file_basename_split_on_period) !=# 1
    let l:file_extname = l:file_basename_split_on_period[-1]
    unlet l:file_basename_split_on_period[-1]
  endif
  let l:file_basename_no_extension = join(l:file_basename_split_on_period, '.')

  " TODO: relativeFile implementation
  " TODO: use maktaba for this?
  let l:new_vars = {
      \ 'workspaceFolder': l:workspace,
      \ 'workspaceFolderBasename': split(l:workspace, '^.*/')[0],
      \ 'file': a:file,
      \ 'relativeFile': '',
      \ 'fileBasename': l:file_basename,
      \ 'fileBasenameNoExtension': l:file_basename_no_extension,
      \ 'fileDirname': matchstr(a:file, '^.*\(/\)\@='),
      \ 'fileExtname': l:file_extname,
      \ 'cwd': a:cwd,
      \ 'lineNumber': a:curpos[1],
      \ 'selectedText': a:selection,
      \ 'execPath': dapper#settings#VSCodeExecutable(),
      \ }
  return l:new_vars
endfunction

" TODO: get visual selection using https://stackoverflow.com/a/6271254,
" TODO: attribute that guy

" BRIEF:  Determine the value of VSCode's debugging/task variables.
" PARAM:  relative_to   (v:t_string?)   Start searching from this directory.
"     Defaults to the current working directory.
let s:vscode_variables = {
    \ 'workspaceFolder': '',
    \ 'workspaceFolderBasename': '',
    \ 'file': '',
    \ 'relativeFile': '',
    \ 'fileBasename': '',
    \ 'fileBasenameNoExtension': '',
    \ 'fileDirname': '',
    \ 'fileExtname': '',
    \ 'cwd': '',
    \ 'lineNumber': '',
    \ 'selectedText': '',
    \ 'execPath': '',
    \ }
function! dapper#vscode#SetVSCodeVariables(...) abort
  let a:relative_to = get(a:000, 0, getcwd())
  if type(a:relative_to) !=# v:t_string
    throw 'ERROR(WrongType) Given dirname isn''t a string: '
        \ . dapper#helpers#StrDump(a:relative_to)
  endif

  try
    let l:workspace = dapper#vscode#FindWorkspace(a:relative_to)
  catch /ERROR(NotFound)/
    " propagate this exception
    throw v:exception
  endtry

  " let s:vscode_variables['workspaceFolder'] = l:workspace
  " let l:basename = split(l:workspace, '^.*/')
  " let s:vscode_variables['workspaceFolderBasename'] = l:workspace

  " TODO
endfunction

" BRIEF:  If possible, parse and return the nearest `launch.json`.
function! dapper#vscode#GetLaunchJSON() abort
  if empty(s:vscode_variables['workspaceFolder'])
    throw 'ERROR(NotFound) Workspace folder not set!'
  endif
  try
    let l:launch_json =
        \ readfile(s:vscode_variables['workspaceFolder'].'/launch.json')
    let l:json = json_decode(l:launch_json)
  catch /E484/  " Can't open file
    let l:err_text = 'Could not open launch.json for parsing.'
    call g:dapper_debug_logger.notifyReport(
        \ 'error',
        \ l:err_text,
        \ '(dapper#vscode#SetVSCodeVariables) Tried reading: '.l:launch_json
            \ . "\nGot exception: " . v:exception)
    throw 'E484: '.l:err_text
  catch /E474/  " Failed to parse
    let l:err_text = 'Could not parse contents of launch.json.'
    call g:dapper_debug_logger.notifyReport(
        \ 'error',
        \ l:err_text,
        \ '(dapper#vscode#SetVSCodeVariables) Tried parsing: '.l:launch_json
            \ . "\nGot parse error: " . v:exception)
    throw 'E474: '.l:err_text
  endtry
  return l:json
endfunction
