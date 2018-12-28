function! dapper#dap#TerminateThreadsArguments() abort
  let l:new = {
    \ 'TYPE': {'TerminateThreadsArguments': 1},
    \ 'threadIds': [],
  \ }
  return l:new
endfunction
