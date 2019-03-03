""
" @public
" @dict Response
" @function dapper#dap#Response#New([success] [command] [msg_or_body])
"
" Construct a DebugProtocol.Response object.
"
" @default success=1
" @default command=''
" @throws WrongType if [success] is not a bool, [command] is not a string, or if: [success] is true and [msg_or_body] is not a dict; or [success] is false and [msg_or_body] is not a string.
function! dapper#dap#Response#New(...) abort
  let l:success = typevim#ensure#IsBool(get(a:000, 0, 1))
  let l:command = maktaba#ensure#IsString(get(a:000, 1, ''))
  let l:msg_or_body = get(a:000, 2, v:null)
  if l:msg_or_body is v:null
    let l:msg_or_body = l:success ? {} : ''
  else
    if l:success | call maktaba#ensure#IsDict(l:msg_or_body)
    else         | call maktaba#ensure#IsString(l:msg_or_body)
    endif
  endif

  let l:new = typevim#make#Instance(dapper#dap#Response())
  let l:new.type = 'response'
  let l:new.success = l:success
  let l:new.command = l:command
  if l:success
    let l:new.body = l:msg_or_body
  else
    let l:new.message = l:msg_or_body
  endif

  return dapper#MiddleTalker#VimifyMessage(l:new)
endfunction
