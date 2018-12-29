function! dapper#dap#TerminateThreadsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'TerminateThreadsArguments': 1},
    \ 'threadIds': [],
  \ }
  return l:new
endfunction
