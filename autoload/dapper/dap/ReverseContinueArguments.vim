function! dapper#dap#ReverseContinueArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ReverseContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
