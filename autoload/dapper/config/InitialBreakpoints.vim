function! dapper#dap#InitialBreakpoints() abort
  let l:new = {
    \ 'TYPE': {'InitialBreakpoints': 1},
    \ 'bps': {},
    \ 'function_bps': {},
    \ 'exception_bps': {},
  \ }
  return l:new
endfunction
