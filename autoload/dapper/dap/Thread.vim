function! dapper#dap#Thread#new() abort
  let l:new = {
    \ 'TYPE': {'Thread': 1},
    \ 'id': 0,
    \ 'name': '',
  \ }
  return l:new
endfunction
