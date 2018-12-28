function! dapper#dap#Variable() abort
  let l:new = {
    \ 'TYPE': {'Variable': 1},
    \ 'name': '',
    \ 'value': '',
    \ 'type': '',
    \ 'presentationHint': {},
    \ 'evaluateName': '',
    \ 'variablesReference': 0,
    \ 'namedVariables': 0,
    \ 'indexedVariables': 0,
  \ }
  return l:new
endfunction
