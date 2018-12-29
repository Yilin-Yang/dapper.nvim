function! dapper#dap#ModulesViewDescriptor#new() abort
  let l:new = {
    \ 'TYPE': {'ModulesViewDescriptor': 1},
    \ 'columns': [],
  \ }
  return l:new
endfunction
