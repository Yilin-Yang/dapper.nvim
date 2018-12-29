function! dapper#dap#ScopesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ScopesArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ScopesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ScopesArguments')
    throw '(dapper#dap#ScopesArguments) Object is not of type ScopesArguments: ' . string(a:object)
  endif
endfunction
