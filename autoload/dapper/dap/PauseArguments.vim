function! dapper#dap#PauseArguments#new() abort
  let l:new = {
    \ 'TYPE': {'PauseArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
