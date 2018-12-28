function! dapper#dap#PauseArguments() abort
  let l:new = {
    \ 'TYPE': {'PauseArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction
