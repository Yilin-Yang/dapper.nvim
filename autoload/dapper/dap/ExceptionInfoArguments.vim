function! dapper#dap#ExceptionInfoArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionInfoArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionInfoArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionInfoArguments')
  try
    let l:err = '(dapper#dap#ExceptionInfoArguments) Object is not of type ExceptionInfoArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ExceptionInfoArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
