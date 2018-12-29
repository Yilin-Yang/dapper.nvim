function! dapper#dap#SetBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetBreakpointsArguments': 1},
    \ 'source': {},
    \ 'breakpoints': [],
    \ 'lines': [],
    \ 'sourceModified': v:false,
  \ }
  return l:new
endfunction
