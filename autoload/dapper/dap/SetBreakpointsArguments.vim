function! dapper#dap#SetBreakpointsArguments() abort
  let l:new = {
    \ 'TYPE': {'SetBreakpointsArguments': 1},
    \ 'source': {},
    \ 'breakpoints': [],
    \ 'lines': [],
    \ 'sourceModified': v:false,
  \ }
  return l:new
endfunction
