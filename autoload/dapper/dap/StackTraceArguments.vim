function! dapper#dap#StackTraceArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StackTraceArguments': 1},
    \ 'threadId': 0,
    \ 'startFrame': 0,
    \ 'levels': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction
