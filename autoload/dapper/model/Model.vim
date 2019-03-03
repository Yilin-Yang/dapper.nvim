""
" @dict Model
" Encapsulates the state of the debugging process.
"
" Model is primarily responsible for managing the VimL frontend's knowledge of
" the debugger's state. It sends `ThreadsRequest`s in response to
" `ThreadEvent`s and `StoppedEvent`s, and starts the "request waterfall"
" described by the Debug Adapter Protocol specification overview.
"
" Only objects in the `dapper#model` namespace should directly modify the
" model state. (`dapper#view` objects can modify the model state indirectly,
" by sending DebugProtocol.Request messages.)

let s:typename = 'Model'
let s:middletalker_interface = dapper#MiddleTalker#Interface()

""
" @public
" @function dapper#model#Model#Interface()
" @dict Model
" Returns the interface that Model implements.
function! dapper#model#Model#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'thread': typevim#Func(),
        \ 'threads': typevim#Func(),
        \ 'functionBps': typevim#Func(),
        \ 'exceptionBps': typevim#Func(),
        \ 'sources': typevim#Func(),
        \ 'capabilities': typevim#Func(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction

""
" @dict Model
" @function dapper#model#Model#New({message_passer})
" Construct a new Model.
"
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface.
function! dapper#model#Model#New(message_passer) abort
  call typevim#ensure#Implements(a:message_passer, s:middletalker_interface)
  let l:new = {
      \ '_ids_to_running': {},
      \ '_ids_to_stopped': {},
      \ '_function_bps': {},
      \ '_exception_bps': {},
      \ '_sources': {},
      \ '_capabilities': {},
      \ '_message_passer': a:message_passer,
      \ 'thread': function('dapper#model#Model#thread'),
      \ 'threads': function('dapper#model#Model#threads'),
      \ 'functionBps': function('dapper#model#Model#functionBps'),
      \ 'exceptionBps': function('dapper#model#Model#exceptionBps'),
      \ 'sources': function('dapper#model#Model#sources'),
      \ 'capabilities': function('dapper#model#Model#capabilities'),
      \ 'Receive': function('dapper#model#Model#Receive'),
      \ 'Update': function('dapper#model#Model#Update'),
      \ '_RecvEvent': function('dapper#model#Model#_RecvEvent'),
      \ '_ReceiveThreadsResponse': function('dapper#model#Model#_ReceiveThreadsResponse'),
      \ '_ThreadFromEvent': function('dapper#model#Model#_ThreadFromEvent'),
      \ '_ArchiveThread': function('dapper#model#Model#_ArchiveThread'),
      \ '_ReqThreads': function('dapper#model#Model#_ReqThreads'),
      \ }
  call typevim#make#Class(s:typename, l:new)
  call typevim#ensure#Implements(l:new, dapper#model#Model#Interface())

  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)

  call a:message_passer.Subscribe('InitializeResponse', l:new.Receive)
  call a:message_passer.Subscribe('ThreadEvent',        l:new.Receive)
  call a:message_passer.Subscribe('StoppedEvent',       l:new.Receive)
  call a:message_passer.Subscribe('ThreadsResponse',    l:new.Receive)

  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict Model
" Prompt the Model to update its contents.
function! dapper#model#Model#Update() abort dict
  call s:CheckType(l:self)
  call l:self._message_passer.Request('threads', {}, l:self.Receive)
endfunction

""
" @public
" @dict Model
" Returns a Thread model object with the requested numerical {tid}.
" @throws NotFound if a matching thread can't be found.
" @throws WrongType if {tid} isn't a number.
function! dapper#model#Model#thread(tid) abort dict
  call maktaba#ensure#IsNumber(a:tid)
  call s:CheckType(l:self)

  let l:running = l:self._ids_to_running
  if !has_key(l:running, a:tid)
    let l:stopped = l:self._ids_to_stopped
    if has_key(l:stopped, a:tid) | return l:stopped[a:tid] | endif
    throw maktaba#error#NotFound('No thread with ID: %s', a:tid)
  endif

  return l:running[a:tid]
endfunction

""
" @public
" @dict Model
" Returns a dictionary of numerical thread IDs to all stored threads. If
" [include_exited] is true, the returned dictionary will also include stopped
" threads.
"
" @default include_exited=0
" @throws WrongType if [include_exited] is not a bool.
function! dapper#model#Model#threads(...) abort dict
  call s:CheckType(l:self)
  let l:include_exited = typevim#ensure#IsBool(get(a:000, 0, 0))
  let l:to_return = copy(l:self._ids_to_running)  " shallow copy
  if !l:include_exited | return l:to_return | endif
  let l:exited = l:self._ids_to_stopped
  for [l:tid, l:thread] in items(l:exited)
    let l:to_return[l:tid] = l:thread
  endfor
  return l:to_return
endfunction

""
" @dict Model
" Returns stored function breakpoints.
" TODO
function! dapper#model#Model#functionBps() abort dict
  call s:CheckType(l:self)
  return l:self._function_bps
endfunction

""
" @dict Model
" Returns stored exception breakpoints.
" TODO
function! dapper#model#Model#exceptionBps() abort dict
  call s:CheckType(l:self)
  if empty(l:self['_exception_bps'])
    throw 'ERROR(NotFound) (dapper#model#Model) '
        \ . 'ExceptionBreakpoints not yet initialized'
  endif
  return l:self._exception_bps
endfunction

""
" @dict Model
" Returns all stored @dict(DebugSource)s.
" TODO
function! dapper#model#Model#sources() abort dict
  call s:CheckType(l:self)
  if empty(l:self['_sources'])
    throw 'ERROR(NotFound) (dapper#model#Model) '
        \ . 'DebugSources not yet initialized'
  endif
  return l:self._sources
endfunction

""
" @public
" @dict Model
" Returns the capabilities of the running debug adapter.
"
" @throws NotFound if capabilities have not yet been received.
function! dapper#model#Model#capabilities() abort dict
  call s:CheckType(l:self)
  if empty(l:self._capabilities)
    throw maktaba#error#NotFound('capabilities have not yet been received!')
  endif
  return deepcopy(l:self._capabilities)
endfunction

""
" @public
" @dict Model
" Update from incoming Debug Adapter Protocol messages.
"
" @throws WrongType if {msg} is not a dict, or if it is not a @dict(DapperMessage).
function! dapper#model#Model#Receive(msg) abort dict
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#DapperMessage())
  let l:typename = a:msg.vim_msg_typename
  if l:typename ==# 'ThreadEvent'
    call l:self._ReqThreads()
    call l:self._RecvEvent(a:msg)
  elseif l:typename ==# 'StoppedEvent'
    call l:self._ReqThreads()
  elseif l:typename ==# 'ThreadsResponse'
    call l:self._ReceiveThreadsResponse(a:msg)
  elseif l:typename ==# 'InitializeResponse'
    " set capabilities
    let l:capabilities = has_key(a:msg, 'body') ? a:msg.body : {}
    let l:self._capabilities = l:capabilities

    " initialize ExceptionBreakpoints object
    let l:filters = []
    if has_key(l:capabilities, 'exceptionBreakpointFilters')
      let l:filters = l:capabilities.exceptionBreakpointFilters
    endif
    let l:self._exception_bps =
        \ dapper#model#ExceptionBreakpoints#new(
            \ l:filters, l:self._message_passer)

    " initialize DebugSources object
    let l:self._sources =
        \ dapper#model#DebugSources#new(
            \ l:self._message_passer, l:capabilities)
  else
    call l:self._message_passer.NotifyReport(
        \ 'info',
        \ 'model#Model Received '.l:typename.', for some reason(?)',
        \ a:msg
        \ )
  endif
endfunction

""
" @dict Model
" Process an incoming ThreadEvent; either create a new thread, or mark an
" existing thread as having exited.
" @throws WrongType if {event} is not a ThreadEvent.
function! dapper#model#Model#_RecvEvent(event) abort dict
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:event, dapper#dap#ThreadEvent())
  " TODO
  " make Thread object
  let l:body = a:event.body
  let l:reason = l:body.reason
  let l:long_msg = typevim#object#PrettyPrint(l:body)
  if l:reason ==# 'started'
    call l:self._ThreadFromEvent(l:body)
  elseif l:reason ==# 'exited'
    call l:self._ArchiveThread(l:body)
  else
    try
      let l:thread = l:self.thread(l:body.threadId)
      call l:thread.UpdateProps(l:body)
    catch
    endtry
      let l:long_msg = 'Unrecognized reason: '.l:reason."\n".l:long_msg
  endif
  call l:self._message_passer.NotifyReport(
      \ 'info',
      \ 'model#Model received ThreadEvent',
      \ l:long_msg
      \ )
endfunction

""
" @dict Model
" Process an incoming ThreadsResponse. Update running threads and push the
" update to subscribed listeners.
"
" @throws WrongType if {response} is not a ThreadsResponse.
function! dapper#model#Model#_ReceiveThreadsResponse(response) abort dict
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:response, dapper#dap#ThreadsResponse())
  if !a:response.success
    call l:self._message_passer.NotifyReport(
        \ 'error',
        \ '(model#Model) ThreadsRequest failed outright!',
        \ a:response)
    return
  endif
  let l:thread_interface = dapper#dap#Thread()
  let l:threads = a:response.body.threads
  let l:i = -1 | while l:i <# len(l:threads)
    " note: threads should be DebugProtocol.Thread objects
    let l:thread = l:threads[l:i]
    if !typevim#value#Implements(l:thread, l:thread_interface)
      call l:self._message_passer.NotifyReport(
          \ 'warn',
          \ '(model#Model) Received malformed thread object',
          \ l:thread)
      continue
    endif
    let l:tid  = l:thread.id
    let l:name = l:thread.name
    let l:running = l:self._ids_to_running
    let l:stopped = l:self._ids_to_stopped
    if has_key(l:running, l:tid)
      call l:running[l:tid].Update(l:thread)
    elseif has_key(l:stopped, l:tid)
      call l:stopped[l:tid].Update(l:thread)
    else
      call l:self._ThreadFromEvent(l:thread)
      let l:new_thread = l:self.thread(l:tid)
      call l:self._message_passer.NotifyReport(
          \ 'debug',
          \ '(model#Model) got/updating unknown Thread:'.l:tid,
          \ l:new_thread)
    endif
  let l:i += 1 | endwhile
endfunction

""
" @dict Model
" Add a new Thread object from the body of a ThreadEvent.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_ThreadFromEvent(body) abort dict
  call s:CheckType(l:self)

  let l:thread = dapper#model#Thread#New(
      \ a:body,
      \ l:self._message_passer)
  let l:self._ids_to_running[l:thread.id()] = l:thread

  call l:self['_message_passer'].NotifyReport(
      \ 'info',
      \ 'model#Model constructed new Thread object.',
      \ l:thread)
endfunction

" BRIEF:  Process an exited Thread.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_ArchiveThread(body) abort dict
  call s:CheckType(l:self)
  let l:tid = a:body.threadId
  let l:brief = 'model#Model archived exited thread:'.l:tid
  let l:kind = 'info'
  let l:long_msg = ''
  try
    let l:thread = l:self._ids_to_running[l:tid]
    call l:thread.Update(a:body, 0)
    unlet l:self._ids_to_running[l:tid]
    let l:self._ids_to_stopped[l:tid] = l:thread
    let l:long_msg = 'Thread archived.'
    " TODO: destroy older threads after this gets too large
  catch /ERROR(NotFound)/
    let l:brief = 'model#Model Unknown thread exited:'.l:tid
    let l:kind = 'error'
    let l:long_msg = 'Model state unchanged.'
  endtry
  call l:self._message_passer.NotifyReport(
      \ l:kind,
      \ l:brief,
      \ l:long_msg )
endfunction

" BRIEF:  Request all active threads from the debug adapter.
function! dapper#model#Model#_ReqThreads() abort dict
  call s:CheckType(l:self)
  call l:self._message_passer.Request(
      \ 'threads', {}, function('dapper#model#Model#Receive', l:self))
endfunction
