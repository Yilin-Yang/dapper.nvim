function! dapper#dap#ExceptionBreakpointsFilter() abort
  let l:new = {
    \ 'TYPE': {'ExceptionBreakpointsFilter': 1},
    \ 'filter': '',
    \ 'label': '',
    \ 'default': v:false,
  \ }
  return l:new
endfunction
