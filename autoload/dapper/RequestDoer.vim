let s:typename = 'RequestDoer'

""
" @dict RequestDoer
" Sends the given {command} with the given {request_args} and resolves with
" the results.

""
" @dict RequestDoer
" Construct a RequestDoer.
"
" @throws WrongType if {message_passer} doesn't implement a MiddleTalker interface, {command} is not a string, {request_args} is not a dict.
function! dapper#RequestDoer#New(message_passer, command, request_args) abort
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  call maktaba#ensure#IsString(a:command)
  call maktaba#ensure#IsDict(a:request_args)
  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_command': a:command,
      \ '_request_args': a:request_args,
      \ 'StartDoing': typevim#make#Member('StartDoing'),
      \ }
  return typevim#make#Derived(s:typename, typevim#Doer#New(), l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict RequestDoer
" Send the stored request.
function! dapper#RequestDoer#StartDoing() dict abort
  call s:CheckType(l:self)
  let l:self.Resolve = typevim#object#Bind(l:self.Resolve, l:self)
  call l:self._message_passer.Request(
      \ l:self._command, l:self._request_args, l:self.Resolve)
endfunction
