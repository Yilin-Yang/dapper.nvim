function! dapper#dap#ColumnDescriptor#new() abort
  let l:new = {
    \ 'TYPE': {'ColumnDescriptor': 1},
    \ 'attributeName': '',
    \ 'label': '',
    \ 'format': '',
    \ 'type': '',
    \ 'width': 0,
  \ }
  return l:new
endfunction
