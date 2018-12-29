function! dapper#dap#StackTraceArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StackTraceArguments': 1},
    \ 'threadId': 0,
    \ 'startFrame': 0,
    \ 'levels': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#StackTraceArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackTraceArguments')
    throw '(dapper#dap#StackTraceArguments) Object is not of type StackTraceArguments: ' . string(a:object)
  endif
endfunction
