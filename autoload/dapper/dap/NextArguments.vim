function! dapper#dap#NextArguments#new() abort
  let l:new = {
    \ 'TYPE': {'NextArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#NextArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'NextArguments')
  try
    let l:err = '(dapper#dap#NextArguments) Object is not of type NextArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#NextArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
