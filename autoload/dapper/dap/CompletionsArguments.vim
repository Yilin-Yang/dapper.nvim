function! dapper#dap#CompletionsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'CompletionsArguments': 1},
    \ 'frameId': 0,
    \ 'text': '',
    \ 'column': 0,
    \ 'line': 0,
  \ }
  return l:new
endfunction
