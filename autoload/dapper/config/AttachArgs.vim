function! dapper#config#AttachArgs#new(restart) abort
  let l:new = {
    \ 'TYPE': {'AttachArgs': 1},
    \ '__restart': a:restart,
  \ }
  return l:new
endfunction

function! dapper#config#AttachArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'AttachArgs')
  try
    let l:err = '(dapper#config#AttachArgs) Object is not of type AttachArgs: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#config#AttachArgs) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
