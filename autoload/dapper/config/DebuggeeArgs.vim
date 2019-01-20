" BRIEF:  Arguments for starting the debuggee process.

" BRIEF:  Construct a `DebuggeeArgs` object.
" PARAM:  request (v:t_string)  `launch` or `attach`.
" PARAM:  name    (v:t_string)  'Human-friendly' name for this configuration.
" PARAM:  args  (DebugProtocol.LaunchRequestArguments | AttachRequestArguments?)
"     Other arguments to provide to the debug adapter, to start a
"     debugger/debuggee or attach to a preexisting one.
function! dapper#config#DebuggeeArgs#new(
    \ request,
    \ name,
    \ args,
    ) abort
  " TODO type checks?
  let l:new = {
      \ 'TYPE': {'DebuggeeArgs': 1},
      \ 'request': a:request,
      \ 'name': a:name,
      \ 'args': a:args,
      \ }
  return l:new
endfunction

function! dapper#config#DebuggeeArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DebuggeeArgs')
  try
    let l:err = '(dapper#config#DebuggeeArgs) Object is not of type DebuggeeArgs: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#config#DebuggeeArgs) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
