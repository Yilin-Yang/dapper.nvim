function! dapper#dap#Request#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let l:new['type'] = 'request'
  let l:new['command'] = ''
  let l:new['arguments'] = ''
  return l:new
endfunction

function! dapper#dap#Request#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Request')
    throw '(dapper#dap#Request) Object is not of type Request: ' . string(a:object)
  endif
endfunction
