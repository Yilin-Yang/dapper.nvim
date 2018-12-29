function! dapper#dap#ModulesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ModulesArguments': 1},
    \ 'startModule': 0,
    \ 'moduleCount': 0,
  \ }
  return l:new
endfunction
