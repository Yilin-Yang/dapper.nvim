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
