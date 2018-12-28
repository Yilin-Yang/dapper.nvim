function! dapper#dap#FunctionBreakpoint() abort
  let l:new = {
    \ 'TYPE': {'FunctionBreakpoint': 1},
    \ 'name': '',
    \ 'condition': '',
    \ 'hitCondition': '',
  \ }
  return l:new
endfunction
