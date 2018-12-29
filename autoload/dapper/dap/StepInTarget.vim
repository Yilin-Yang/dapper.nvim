function! dapper#dap#StepInTarget#new() abort
  let l:new = {
    \ 'TYPE': {'StepInTarget': 1},
    \ 'id': 0,
    \ 'label': '',
  \ }
  return l:new
endfunction
