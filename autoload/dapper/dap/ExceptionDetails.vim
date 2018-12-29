function! dapper#dap#ExceptionDetails#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionDetails': 1},
    \ 'message': '',
    \ 'typeName': '',
    \ 'fullTypeName': '',
    \ 'evaluateName': '',
    \ 'stackTrace': '',
    \ 'innerException': [],
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionDetails#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionDetails')
    throw '(dapper#dap#ExceptionDetails) Object is not of type ExceptionDetails: ' . string(a:object)
  endif
endfunction
