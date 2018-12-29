function! dapper#config#AttachArgs#new(restart) abort
  let l:new = {
    \ 'TYPE': {'AttachArgs': 1},
    \ '__restart': a:restart,
  \ }
  return l:new
endfunction

function! dapper#config#AttachArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'AttachArgs')
    throw '(dapper#config#AttachArgs) Object is not of type AttachArgs: ' . a:object
  endif
endfunction
