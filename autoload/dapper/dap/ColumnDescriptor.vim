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

function! dapper#dap#ColumnDescriptor#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ColumnDescriptor')
    throw '(dapper#dap#ColumnDescriptor) Object is not of type ColumnDescriptor: ' . string(a:object)
  endif
endfunction
