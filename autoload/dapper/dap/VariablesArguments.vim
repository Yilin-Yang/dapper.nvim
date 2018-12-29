function! dapper#dap#VariablesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'VariablesArguments': 1},
    \ 'variablesReference': 0,
    \ 'filter': '',
    \ 'start': 0,
    \ 'count': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction
