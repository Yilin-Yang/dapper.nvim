function! dapper#dap#SetFunctionBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetFunctionBreakpointsArguments': 1},
    \ 'breakpoints': [],
  \ }
  return l:new
endfunction
