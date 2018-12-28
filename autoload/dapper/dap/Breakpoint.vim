function! dapper#dap#Breakpoint() abort
  let l:new = {
    \ 'TYPE': {'Breakpoint': 1},
    \ 'id': 0,
    \ 'verified': v:false,
    \ 'message': '',
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction
