function! dapper#dap#Event#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let l:new['type'] = 'event'
  let l:new['event'] = ''
  let l:new['body'] = ''
  return l:new
endfunction

function! dapper#dap#Event#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Event')
  try
    let l:err = '(dapper#dap#Event) Object is not of type Event: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#Event) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
