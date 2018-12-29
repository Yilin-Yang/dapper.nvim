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
    throw '(dapper#dap#ExceptionOptions) Object is not of type ExceptionOptions: ' . string(a:object)
  endif
endfunction
