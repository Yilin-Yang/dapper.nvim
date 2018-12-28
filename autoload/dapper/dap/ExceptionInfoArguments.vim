function! dapper#dap#ExceptionInfoArguments() abort
  let l:new = {
    \ 'TYPE': {'ExceptionInfoArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
