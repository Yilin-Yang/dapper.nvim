function! dapper#dap#SourceBreakpoint() abort
  let l:new = {
    \ 'TYPE': {'SourceBreakpoint': 1},
    \ 'line': 0,
    \ 'column': 0,
    \ 'condition': '',
    \ 'hitCondition': '',
    \ 'logMessage': '',
  \ }
  return l:new
endfunction
