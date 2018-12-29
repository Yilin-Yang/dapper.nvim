function! dapper#dap#ScopesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ScopesArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction
