function! dapper#dap#SetVariableArguments() abort
  let l:new = {
    \ 'TYPE': {'SetVariableArguments': 1},
    \ 'variablesReference': 0,
    \ 'name': '',
    \ 'value': '',
    \ 'format': {},
  \ }
  return l:new
endfunction
