function! dapper#dap#NextArguments#new() abort
  let l:new = {
    \ 'TYPE': {'NextArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#NextArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'NextArguments')
    throw '(dapper#dap#NextArguments) Object is not of type NextArguments: ' . string(a:object)
  endif
endfunction
