function! dapper#dap#ExceptionDetails() abort
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
