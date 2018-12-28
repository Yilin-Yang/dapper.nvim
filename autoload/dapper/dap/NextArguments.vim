function! dapper#dap#NextArguments() abort
  let l:new = {
    \ 'TYPE': {'NextArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
