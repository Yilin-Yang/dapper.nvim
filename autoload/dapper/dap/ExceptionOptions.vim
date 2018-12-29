function! dapper#dap#ExceptionOptions#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionOptions': 1},
    \ 'path': [],
    \ 'breakMode': {},
  \ }
  return l:new
endfunction
