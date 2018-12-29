function! dapper#dap#StepOutArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepOutArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
