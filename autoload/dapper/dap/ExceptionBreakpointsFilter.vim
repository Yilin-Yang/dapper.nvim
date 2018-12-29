function! dapper#dap#ExceptionBreakpointsFilter#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionBreakpointsFilter': 1},
    \ 'filter': '',
    \ 'label': '',
    \ 'default': v:false,
  \ }
  return l:new
endfunction
