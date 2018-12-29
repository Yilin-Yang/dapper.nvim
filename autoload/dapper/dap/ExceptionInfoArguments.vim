function! dapper#dap#ExceptionInfoArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionInfoArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionInfoArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionInfoArguments')
    throw '(dapper#dap#ExceptionInfoArguments) Object is not of type ExceptionInfoArguments: ' . string(a:object)
  endif
endfunction
