function! dapper#dap#SetExceptionBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetExceptionBreakpointsArguments': 1},
    \ 'filters': '',
    \ 'exceptionOptions': [],
  \ }
  return l:new
endfunction
