function! dapper#dap#StepInArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepInArguments': 1},
    \ 'threadId': 0,
    \ 'targetId': 0,
  \ }
  return l:new
endfunction
