" BRIEF:  Represent an exception breakpoint.
" DETAILS:  Has no actual equivalent in the debug adapter protocol. Several of
"     these are meant to be concatenated into a
"     `SetExceptionBreakpointsArguments` object.
function! dapper#dap#ExceptionBreakpoint#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionBreakpoint': 1},
    \ 'filter': '',
    \ 'exceptionOptions': {
      \ 'breakMode': 'always',
      \ 'path': [],
      \ },
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionBreakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionBreakpoints')
  try
    let l:err = '(dapper#dap#ExceptionBreakpoints) Object is not of type ExceptionBreakpoints: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ExceptionBreakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
