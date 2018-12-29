function! dapper#dap#Message#new() abort
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

function! dapper#dap#Message#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Message')
    throw '(dapper#dap#Message) Object is not of type Message: ' . string(a:object)
  endif
endfunction
