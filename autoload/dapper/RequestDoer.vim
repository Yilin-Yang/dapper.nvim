let s:typename = 'RequestDoer'

let s:FUNC_PREFIX = 'dapper#RequestDoer#'
let s:PROTOTYPE = {
    \ 'StartDoing': function(s:FUNC_PREFIX.'StartDoing'),
    \ 'Receive': function(s:FUNC_PREFIX.'Receive'),
    \ }
call typevim#make#Derived(s:typename, typevim#Doer#New(), s:PROTOTYPE)

let s:known_good_middletalker = v:null

""
" @dict RequestDoer
" Sends the given {command} with the given {request_args} and resolves with
" the results.

""
" @public
" @function dapper#RequestDoer#New({message_passer}, {command}, {request_args})
" @dict RequestDoer
" Construct a RequestDoer. {command} is the value of the "command" field of a
" DebugProtocol.Request, while {request_args} is the value of the "arguments"
" field of the same.
"
" @throws WrongType if {message_passer} doesn't implement a MiddleTalker interface, {command} is not a string, {request_args} is not a dict.
function! dapper#RequestDoer#New(message_passer, command, request_args) abort
  if typevim#ensure#IsDict(a:message_passer) isnot s:known_good_middletalker
    call typevim#ensure#Implements(
        \ a:message_passer, dapper#MiddleTalker#Interface())
    let s:known_good_middletalker = a:message_passer
  endif
  call maktaba#ensure#IsString(a:command)
  call maktaba#ensure#IsDict(a:request_args)
  let l:new = deepcopy(s:PROTOTYPE)
  call extend(l:new, {
      \ '_message_passer': a:message_passer,
      \ '_command': a:command,
      \ '_request_args': a:request_args,
      \ })
  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict RequestDoer
" Send the stored request.
function! dapper#RequestDoer#StartDoing() dict abort
  call s:CheckType(l:self)
  call l:self._message_passer.Request(
      \ l:self._command, l:self._request_args, l:self.Receive)
endfunction

""
" @dict RequestDoer
" Process a response to the sent request.
function! dapper#RequestDoer#Receive(msg) dict abort
  call s:CheckType(l:self)
  if !typevim#value#Implements(a:msg, dapper#dap#Response())
    call l:self._message_passer.NotifyReport(
        \ 'error', 'Received malformed response in RequestDoer',
        \ a:msg, l:self)
    return
  endif
  if a:msg.success
    call l:self.Resolve(a:msg)
  else
    call l:self.Reject(a:msg)
  endif
endfunction
