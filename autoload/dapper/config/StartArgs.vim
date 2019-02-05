" BRIEF:  All arguments supplied to the middle-end; starts adapter and debuggee.

" BRIEF:  Construct a new StartArgs object.
" PARAM:  adapter_config  (dapper#config#DebugAdapterConfig)  Configuration
"     for the debug adapter itself.
" PARAM:  debuggee_args   (dapper#config#DebuggeeArgs)  Arguments supplied to
"     the debug adapter, to start or attach to a 'debuggee' process.
" PARAM:  vscode_attr     (dapper#config#VSCodeAttributes)  Other attributes
"     from a `launch.json` file that are specific to VSCode.
" PARAM:  locale  (v:t_string?) The ISO-639 locale with which to start the
"     debug adapter. If empty, defaults to the locale of the running vim
"     instance.
function! dapper#config#StartArgs#new(
    \ adapter_config,
    \ debuggee_args,
    \ vscode_attr,
    \ ...
    \ ) abort
  call dapper#config#DebugAdapterConfig#CheckType(a:adapter_config)
  call dapper#config#DebuggeeArgs#CheckType(a:debuggee_args)
  " call dapper#config#VSCodeAttributes#CheckType(a:vscode_attr)
  let a:locale = get(a:000, 0, '')
  let l:default_locale = split(v:ctype, '\.')[0]  " trim, e.g. '.UTF8'
  let l:locale = empty(a:locale) ? l:default_locale : a:locale
  let l:new = {
      \ 'TYPE': {'StartArgs': 1},
      \ 'adapter_config': a:adapter_config,
      \ 'debuggee_args': a:debuggee_args,
      \ 'vscode_attr': a:vscode_attr,
      \ 'locale': a:locale
      \ }
  return l:new
endfunction

function! dapper#config#StartArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StartArgs')
  try
    let l:err = '(dapper#config#StartArgs) Object is not of type StartArgs: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#config#StartArgs) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
