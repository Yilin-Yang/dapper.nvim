function! dapper#dap#StepBackArguments() abort
  let l:new = {
    \ 'TYPE': {'StepBackArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
