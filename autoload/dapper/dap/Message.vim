function! dapper#dap#Message() abort
  let l:new = {
    \ 'TYPE': {'Message': 1},
    \ 'id': 0,
    \ 'format': '',
    \ 'variables': {},
    \ 'sendTelemetry': v:false,
    \ 'showUser': v:false,
    \ 'url': '',
    \ 'urlLabel': '',
  \ }
  return l:new
endfunction
