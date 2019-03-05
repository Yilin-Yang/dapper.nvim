""
" @dict Thread
" Stores information about a running (or stopped) thread.

let s:typename = 'Thread'

let s:thread_event_body = {
    \ 'id?': typevim#Number(),
    \ 'threadId?': typevim#Number(),
    \ 'name?': typevim#String(),
    \ 'reason?': typevim#String()
    \ }
call typevim#make#Interface('ThreadEventBody', s:thread_event_body)

""
" @public
" @function dapper#model#Thread#New({props} {message_passer})
" @dict Thread
" Construct a new Thread object. Will automatically request its own stack
" trace on construction.
"
" {props} is the body of a ThreadEvent (or a similar structure), which can
" contain the following optinal properties:
" - "id" or "threadId", which are numbers.
" - "name", a string.
" - "reason", a string.
"
" @throws WrongType if the {props} are present and don't have the above types, or if {message_passer} isn't a dict.
function! dapper#model#Thread#New(props, message_passer) abort
  call typevim#ensure#Implements(a:props, s:thread_event_body)
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  let l:tid = get(a:props, 'id', get(a:props, 'threadId', 0))
  " TODO asynchronously grab the callstack
  let l:new = {
      \ '_tid': l:tid,
      \ '_name': get(a:props, 'name', 'unnamed'),
      \ '_status': get(a:props, 'reason', '(N/A)'),
      \ '_last_thread_update': localtime(),
      \ '_last_callstack_update': -1,
      \ '_callstack': {},
      \ '_message_passer': a:message_passer,
      \ 'id': typevim#make#Member('id'),
      \ 'name': typevim#make#Member('name'),
      \ 'status': typevim#make#Member('status'),
      \ 'stackTrace': typevim#make#Member('stackTrace'),
      \ 'Receive': typevim#make#Member('Receive'),
      \ 'Update': typevim#make#Member('Update'),
      \ }
  call typevim#make#Class(s:typename, l:new)
  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict Thread
" Returns this thread's unique numerical ID.
function! dapper#model#Thread#id() dict abort
  call s:CheckType(l:self)
  return l:self._tid
endfunction

""
" @public
" @dict Thread
" Returns this thread's name.
function! dapper#model#Thread#name() dict abort
  call s:CheckType(l:self)
  return l:self._name
endfunction

""
" @public
" @dict Thread
" Returns the status of this thread.
function! dapper#model#Thread#status() dict abort
  call s:CheckType(l:self)
  return l:self._status
endfunction

""
" @public
" @dict Thread
" Returns a Promise that, when resolved, returns the thread's StackTrace.
function! dapper#model#Thread#stackTrace() dict abort
  call s:CheckType(l:self)
  let l:callstack = l:self._callstack
  if empty(l:callstack)
      \ || l:self._last_thread_update >=# l:self._last_callstack_update
    let l:doer = dapper#RequestDoer#New(
        \ l:self._message_passer, 'stackTrace', {'threadId': l:self.id()})
    let l:to_return = typevim#Promise#New(l:doer)
    call l:to_return.Then(l:self.Receive)
  else
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(l:callstack)
  endif
  return l:to_return
endfunction

""
" @public
" @dict Thread
" Update this Thread object's stored stack trace from the given {msg}.
"
" @throws BadValue if {msg} is not a dict.
" @throws WrongType if {msg} is not a ProtocolMessage.
function! dapper#model#Thread#Receive(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#ProtocolMessage())
  if a:msg.vim_msg_typename !=# 'StackTraceResponse'
    call l:self._message_passer.NotifyReport(
        \ 'debug',
        \ 'Thread received non-StackTraceResponse, ignoring.',
        \ a:msg,
        \ l:self
        \ )
    return
  elseif !a:msg.success
    call l:self._message_passer.NotifyReport(
        \ 'debug',
        \ 'Thread got failed StackTraceResponse, ignoring.',
        \ a:msg,
        \ l:self
        \ )
    return
  endif
  let l:self._callstack = a:msg
  let l:self._last_callstack_update = localtime()
endfunction

""
" @public
" @dict Thread
" Update the properties of this Thread from {props}, which is the body of a
" ThreadEvent. {props} may contain the following optional properties:
" - "id" or "threadId"
" - "name"
" - "reason"
"
" If [update_stack_trace] is true, calling this function will prompt the
" Thread to update its cached stack trace.
"
" @default update_stack_trace=1
"
" @throws BadValue if {props} is not a dict.
" @throws WrongType if {props} contains the properties above, but with the wrong types, or if [update_stack_trace] is not a bool.
function! dapper#model#Thread#Update(props, ...) dict abort
  call s:CheckType(l:self)
  let l:self._last_thread_update = localtime()
  let a:update_stack_trace = typevim#ensure#IsBool(get(a:000, 0, 1))
  if has_key(a:props, 'id')
    let l:self._id = a:props.id
  elseif has_key(a:props, 'threadId')
    let l:self._id = a:props.threadId
  endif
  if has_key(a:props, 'name')
    let l:self._name = a:props.name
  endif
  if has_key(a:props, 'reason')
    let l:self._status = a:props.reason
  endif
  if a:update_stack_trace
    " TODO
    " let l:self._callstack =
    "     \ dapper#model#StackTrace#new(l:self._id, l:self._message_passer)
  endif
endfunction
