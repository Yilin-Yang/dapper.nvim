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
  try
    let l:err = '(dapper#dap#Message) Object is not of type Message: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#Message) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
