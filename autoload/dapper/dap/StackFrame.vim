function! dapper#dap#StackFrame() abort
  let l:new = {
    \ 'TYPE': {'StackFrame': 1},
    \ 'id': 0,
    \ 'name': '',
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
    \ 'moduleId': 0,
    \ 'presentationHint': '',
  \ }
  return l:new
endfunction
