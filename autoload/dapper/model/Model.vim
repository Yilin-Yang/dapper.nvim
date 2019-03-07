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
" Implements @function(dapper#model#Model#Interface) and
" @function(dapper#interface#UpdatePusher).
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface.
function! dapper#model#Model#New(message_passer) abort
  call typevim#ensure#Implements(a:message_passer, s:middletalker_interface)
  let l:new = {
      \ '_ids_to_running': {},
      \ '_ids_to_stopped': {},
      \ '_to_highlight': v:null,
      \ '_function_bps': {},
      \ '_exception_bps': {},
      \ '_sources': {},
      \ '_capabilities': {},
      \ '_message_passer': a:message_passer,
      \ 'thread': typevim#make#Member('thread'),
      \ 'threads': typevim#make#Member('threads'),
      \ 'functionBps': typevim#make#Member('functionBps'),
      \ 'exceptionBps': typevim#make#Member('exceptionBps'),
      \ 'sources': typevim#make#Member('sources'),
      \ 'capabilities': typevim#make#Member('capabilities'),
      \ 'Receive': typevim#make#Member('Receive'),
      \ 'Update': typevim#make#Member('Update'),
      \ '_ReceiveThreadEvent': typevim#make#Member('_ReceiveThreadEvent'),
      \ '_ReceiveThreadsResponse': typevim#make#Member('_ReceiveThreadsResponse'),
      \ '_ThreadFromEvent': typevim#make#Member('_ThreadFromEvent'),
      \ '_ArchiveThread': typevim#make#Member('_ArchiveThread'),
      \ '_RequestThreads': typevim#make#Member('_RequestThreads'),
      \ '_parent': v:null,
      \ '_children': [],
      \ 'GetParent': typevim#make#Member('GetParent'),
      \ 'SetParent': typevim#make#Member('SetParent'),
      \ 'AddChild': typevim#make#Member('AddChild'),
      \ 'RemoveChild': typevim#make#Member('RemovevChild'),
      \ 'GetChildren': typevim#make#Member('GetChildren'),
      \ 'Push': typevim#make#Member('Push'),
      \ }
  call typevim#make#Class(s:typename, l:new)
  call typevim#ensure#Implements(l:new, dapper#model#Model#Interface())
  call typevim#ensure#Implements(l:new, dapper#interface#UpdatePusher())

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
function! dapper#model#Model#Update() dict abort
  call s:CheckType(l:self)
  call l:self._message_passer.Request('threads', {}, l:self.Receive)
endfunction

""
" @public
" @dict Model
" Returns a Thread model object with the requested numerical {tid}.
" @throws NotFound if a matching thread can't be found.
" @throws WrongType if {tid} isn't a number.
function! dapper#model#Model#thread(tid) dict abort
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
function! dapper#model#Model#threads(...) dict abort
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
function! dapper#model#Model#functionBps() dict abort
  call s:CheckType(l:self)
  return l:self._function_bps
endfunction

""
" @dict Model
" Returns stored exception breakpoints.
" TODO
function! dapper#model#Model#exceptionBps() dict abort
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
function! dapper#model#Model#sources() dict abort
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
function! dapper#model#Model#capabilities() dict abort
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
function! dapper#model#Model#Receive(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#DapperMessage())
  let l:typename = a:msg.vim_msg_typename
  if l:typename ==# 'ThreadEvent'
    call l:self._RequestThreads()
    call l:self._ReceiveThreadEvent(a:msg)
  elseif l:typename ==# 'StoppedEvent'
    call l:self._RequestThreads()
    call l:self._ReceiveThreadEvent(a:msg)
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
    " let l:self._exception_bps =
    "     \ dapper#model#ExceptionBreakpoints#New(
    "         \ l:filters, l:self._message_passer)

    " initialize DebugSources object
    " let l:self._sources =
    "     \ dapper#model#DebugSources#new(
    "         \ l:self._message_passer, l:capabilities)
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
" existing thread as having exited. Set the indicated thread as the thread
" `_to_highlight`.
" @throws WrongType if {event} is not a ThreadEvent.
function! dapper#model#Model#_ReceiveThreadEvent(event) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:event, dapper#dap#ThreadEvent())

  let l:body = a:event.body
  let l:reason = l:body.reason
  let l:long_msg = typevim#object#PrettyPrint(l:body)
  if l:reason ==# 'started'
    call l:self._ThreadFromEvent(l:body)
  elseif l:reason ==# 'exited'
    call l:self._ArchiveThread(l:body)
  else
    let l:long_msg = 'Reason: '.l:reason."\n".l:long_msg
    let l:tid = l:body.threadId
    try
      let l:thread = l:self.thread(l:tid)
    catch /ERROR(NotFound)/
      call l:self._ThreadFromEvent(l:body)
      let l:thread = l:self.thread(l:tid)
    endtry
    call l:thread.Update(l:body)
  endif
  let l:self._to_highlight = l:self.thread(l:body.threadId)
  call l:self._message_passer.NotifyReport(
      \ 'info',
      \ 'model#Model received ThreadEvent',
      \ l:long_msg
      \ )
endfunction

""
" @dict Model
" Process an incoming ThreadsResponse. Update running threads and push the
" update to child objects. Remove children for which the push fails. Reset the
" stored thread `_to_highlight` to null.
"
" @throws WrongType if {response} is not a ThreadsResponse.
function! dapper#model#Model#_ReceiveThreadsResponse(response) dict abort
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

  let l:id_to_highlight = empty(l:self._to_highlight) ?
      \ 'v:null' : l:self._to_highlight.id()
  for l:child in l:self._children
    call l:self._message_passer.NotifyReport(
        \ 'debug',
        \ '(model#Model) Pushing threads, highlight: '.l:id_to_highlight,
        \ l:child)
    try
      if empty(l:self._to_highlight)
        call l:child.Push(l:self.threads(1))
      else
        call l:child.Push(l:self.threads(1), l:self._to_highlight)
      endif
    catch /\(E118\)\|\(E119\)/  " Too many arguments | Not enough arguments
      call l:self._message_passer.NotifyReport(
          \ 'debug',
          \ '(model#Model) Push failed, removing child',
          \ l:child,
          \ v:exception)
      call l:self.RemoveChild(l:child)
    endtry
  endfor
  let l:self._to_highlight = v:null
endfunction

""
" @dict Model
" Add a new Thread object from the body of a ThreadEvent.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_ThreadFromEvent(body) dict abort
  call s:CheckType(l:self)

  let l:thread = dapper#model#Thread#New(
      \ l:self._message_passer,
      \ a:body)
  let l:self._ids_to_running[l:thread.id()] = l:thread

  call l:self._message_passer.NotifyReport(
      \ 'info',
      \ 'model#Model constructed new Thread object.',
      \ l:thread)
endfunction

" BRIEF:  Process an exited Thread.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_ArchiveThread(body) dict abort
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
function! dapper#model#Model#_RequestThreads() dict abort
  call s:CheckType(l:self)
  call l:self._message_passer.Request(
      \ 'threads', {}, function('dapper#model#Model#Receive', l:self))
endfunction

""
" @public
" @dict Model
" Return the Model's parent UpdatePusher.
function! dapper#model#Model#GetParent() dict abort
  call s:CheckType(l:self)
  return l:self._parent
endfunction

""
" @public
" @dict Model
" Set the parent UpdatePusher of this Model.
" @throws BadValue if {new_parent} is not a dict.
" @throws WrongType if {new_parent} does not implement @function(dapper#interface#UpdatePusher()).
function! dapper#model#Model#SetParent(new_parent) dict abort
  call s:CheckType(l:self)
  let l:self._parent =
      \ typevim#ensure#Implements(a:new_parent, dapper#interface#UpdatePusher())
endfunction

""
" @public
" @dict Model
" Add a child UpdatePusher to this object.
" @throws BadValue if {new_child} is not a dict.
" @throws WrongType if {new_child} does not implement @function(dapper#interface#UpdatePusher()).
function! dapper#model#Model#AddChild(new_child) dict abort
  call s:CheckType(l:self)
  call add(
      \ l:self._children,
      \ typevim#ensure#Implements(a:new_child, dapper#interface#UpdatePusher()))
endfunction

""
" @public
" @dict Model
" Remove the child UpdatePusher {to_remove} from this Model's children. Return
" 1 if {to_remove} was found and removed, 0 otherwise.
" @throws BadValue if {to_remove} is not a dict.
" @throws WrongType if {to_remove} does not implement @function(dapper#interface#UpdatePusher()).
function! dapper#model#Model#RemoveChild(to_remove) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:to_remove, dapper#interface#UpdatePusher())
  let l:i = 0 | while l:i <# len(l:self._children)
    let l:child = l:self._children[l:i]
    if l:child is a:to_remove
      unlet l:self._children[l:i]
      return 1
    endif
  let l:i += 1 | endwhile
  return 0
endfunction

""
" @public
" @dict Model
" Returns a copied list of all this Model's children.
function! dapper#model#Model#GetChildren() dict abort
  call s:CheckType(l:self)
  return copy(l:self._children)
endfunction

""
" @public
" @dict Model
" Do nothing.
function! dapper#model#Model#Push(...) dict abort
  call s:CheckType(l:self)
endfunction
