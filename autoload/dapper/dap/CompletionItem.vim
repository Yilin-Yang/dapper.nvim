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

function! dapper#dap#CompletionItem#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'CompletionItem')
    throw '(dapper#dap#CompletionItem) Object is not of type CompletionItem: ' . string(a:object)
  endif
endfunction
