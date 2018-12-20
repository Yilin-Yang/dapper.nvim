function! dapper#dap#Event#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let l:new['type'] = 'event'
  let l:new['event'] = ''
  let l:new['body'] = ''
  return l:new
endfunction
