function! dapper#dap#ContinueArguments() abort
  let l:new = {
    \ 'TYPE': {'ContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
