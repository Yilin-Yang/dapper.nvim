function! dapper#dap#SetFunctionBreakpointsArguments() abort
  let l:new = {
    \ 'TYPE': {'SetFunctionBreakpointsArguments': 1},
    \ 'breakpoints': [],
  \ }
  return l:new
endfunction
