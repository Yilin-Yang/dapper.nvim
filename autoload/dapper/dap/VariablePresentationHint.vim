function! dapper#dap#VariablePresentationHint#new() abort
  let l:new = {
    \ 'TYPE': {'VariablePresentationHint': 1},
    \ 'kind': '',
    \ 'attributes': '',
    \ 'visibility': '',
  \ }
  return l:new
endfunction
