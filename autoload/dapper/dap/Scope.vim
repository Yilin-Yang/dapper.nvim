function! dapper#dap#Scope() abort
  let l:new = {
    \ 'TYPE': {'Scope': 1},
    \ 'name': '',
    \ 'variablesReference': 0,
    \ 'namedVariables': 0,
    \ 'indexedVariables': 0,
    \ 'expensive': v:false,
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction
