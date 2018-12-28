function! dapper#dap#ExceptionOptions() abort
  let l:new = {
    \ 'TYPE': {'ExceptionOptions': 1},
    \ 'path': [],
    \ 'breakMode': {},
  \ }
  return l:new
endfunction
