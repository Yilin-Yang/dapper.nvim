""
" @public
" @dict Event
" @function dapper#dap#Event#New([event] [body])
"
" Construct a DebugProtocol.Event object.
"
" @default event=''
" @default body={}
" @throws WrongType if {event} is not a string.
function! dapper#dap#Event#New(...) abort
  let l:event = maktaba#ensure#IsString(get(a:000, 0, ''))
  let l:body  = get(a:000, 1, {})

  let l:new = typevim#make#Instance(dapper#dap#Event())
  let l:new.type = 'event'
  let l:new.event = l:event
  let l:new.body = l:body

  return dapper#MiddleTalker#VimifyMessage(l:new)
endfunction
