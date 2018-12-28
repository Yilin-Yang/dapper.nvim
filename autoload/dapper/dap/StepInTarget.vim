function! dapper#dap#StepInTarget() abort
  let l:new = {
    \ 'TYPE': {'StepInTarget': 1},
    \ 'id': 0,
    \ 'label': '',
  \ }
  return l:new
endfunction
