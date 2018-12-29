function! dapper#dap#ExceptionOptions#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionOptions': 1},
    \ 'path': [],
    \ 'breakMode': {},
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionOptions#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionOptions')
  try
    let l:err = '(dapper#dap#ExceptionOptions) Object is not of type ExceptionOptions: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ExceptionOptions) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
