function! dapper#dap#GotoArguments() abort
  let l:new = {
    \ 'TYPE': {'GotoArguments': 1},
    \ 'threadId': 0,
    \ 'targetId': 0,
  \ }
  return l:new
endfunction
