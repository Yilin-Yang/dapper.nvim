function! dapper#dap#TerminateThreadsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'TerminateThreadsArguments': 1},
    \ 'threadIds': [],
  \ }
  return l:new
endfunction

function! dapper#dap#TerminateThreadsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'TerminateThreadsArguments')
    throw '(dapper#dap#TerminateThreadsArguments) Object is not of type TerminateThreadsArguments: ' . string(a:object)
  endif
endfunction
