function! dapper#dap#Source#new() abort
  let l:new = {
    \ 'TYPE': {'Source': 1},
    \ 'name': '',
    \ 'path': '',
    \ 'sourceReference': 0,
    \ 'presentationHint': '',
    \ 'origin': '',
    \ 'sources': [],
    \ 'adapterData': {},
    \ 'checksums': [],
  \ }
  return l:new
endfunction

function! dapper#dap#Source#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Source')
    throw '(dapper#dap#Source) Object is not of type Source: ' . string(a:object)
  endif
endfunction
