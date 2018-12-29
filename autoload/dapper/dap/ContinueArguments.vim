function! dapper#dap#ContinueArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ContinueArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ContinueArguments')
    throw '(dapper#dap#ContinueArguments) Object is not of type ContinueArguments: ' . string(a:object)
  endif
endfunction
