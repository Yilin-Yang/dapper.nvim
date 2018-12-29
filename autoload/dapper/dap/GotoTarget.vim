function! dapper#dap#GotoTarget#new() abort
  let l:new = {
    \ 'TYPE': {'GotoTarget': 1},
    \ 'id': 0,
    \ 'label': '',
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction
