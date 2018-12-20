function! dapper#dap#Request#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let l:new['type'] = 'request'
  let l:new['command'] = ''
  let l:new['arguments'] = ''
  return l:new
endfunction
