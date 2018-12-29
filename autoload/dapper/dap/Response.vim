function! dapper#dap#Response#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let l:new['type'] = 'response'
  let l:new['response_seq'] = 0
  let l:new['success'] = v:false
  let l:new['command'] = ''
  let l:new['message'] = ''
  let l:new['body'] = ''
  return l:new
endfunction

function! dapper#dap#Response#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Response')
    throw '(dapper#dap#Response) Object is not of type Response: ' . string(a:object)
  endif
endfunction
