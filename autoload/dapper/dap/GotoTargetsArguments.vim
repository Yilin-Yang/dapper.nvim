function! dapper#dap#GotoTargetsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'GotoTargetsArguments': 1},
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
  \ }
  return l:new
endfunction
