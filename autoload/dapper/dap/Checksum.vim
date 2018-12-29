function! dapper#dap#Checksum#new() abort
  let l:new = {
    \ 'TYPE': {'Checksum': 1},
    \ 'algorithm': {},
    \ 'checksum': '',
  \ }
  return l:new
endfunction
