function! dapper#dap#SetExceptionBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetExceptionBreakpointsArguments': 1},
    \ 'filters': '',
    \ 'exceptionOptions': [],
  \ }
  return l:new
endfunction

function! dapper#dap#SetExceptionBreakpointsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetExceptionBreakpointsArguments')
    throw '(dapper#dap#SetExceptionBreakpointsArguments) Object is not of type SetExceptionBreakpointsArguments: ' . string(a:object)
  endif
endfunction
