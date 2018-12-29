function! dapper#dap#StepInTargetsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepInTargetsArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction
