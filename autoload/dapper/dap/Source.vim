function! dapper#dap#Source() abort
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
