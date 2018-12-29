function! dapper#dap#CompletionItem#new() abort
  let l:new = {
    \ 'TYPE': {'CompletionItem': 1},
    \ 'label': '',
    \ 'text': '',
    \ 'type': {},
    \ 'start': 0,
    \ 'length': 0,
  \ }
  return l:new
endfunction
