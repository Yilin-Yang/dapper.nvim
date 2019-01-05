" BRIEF:  Encapsulates the state of the debugging process.
" DETAILS:  Model is primarily responsible for managing the VimL frontend's
"     knowledge of the debugger's state. It sends `ThreadsRequest`s in
"     response to `ThreadEvent`s and `StoppedEvent`, and starts the 'request
"     waterfall' described by the Debug Adapter Protocol specification overview.
"
"     **Only** objects in the `dapper#model` namespace should directly
"     modify the model state. (`dapper#view` objects can modify the model
"     state 'indirectly', by sending DebugProtocol.Request messages.)

" BRIEF:  Construct a new Model.
" PARAM:  message_passer  (dapper#MiddleTalker)
function! dapper#model#Model#new(message_passer) abort
  let a:debug_logger = get(a:000, 0, dapper#log#DebugLogger#dummy())
  " if !exists('g:dapper_model')
  "   try
  "     call dapper#model#Model#CheckType(g:dapper_model)
  "     return g:dapper_model
  "   catch
  "   endtry
  " endif
  let l:new = {
      \ 'TYPE': {'Model': 1},
      \ '_ids_to_running': {},
      \ '_ids_to_stopped': {},
      \ '_message_passer': a:message_passer,
      \ 'update': function('dapper#model#Model#update'),
      \ 'thread': function('dapper#model#Model#thread'),
      \ 'threads': function('dapper#model#Model#threads'),
      \ 'receive': function('dapper#model#Model#receive'),
      \ '_recvEvent': function('dapper#model#Model#_recvEvent'),
      \ '_recvResponse': function('dapper#model#Model#_recvResponse'),
      \ '_makeThread': function('dapper#model#Model#_makeThread'),
      \ '_archiveThread': function('dapper#model#Model#_archiveThread'),
      \ '_reqThreads': function('dapper#model#Model#_reqThreads'),
      \ }
  call a:message_passer.subscribe(
      \ 'ThreadEvent',
      \ function('dapper#model#Model#receive', l:new))
  call a:message_passer.subscribe(
      \ 'StoppedEvent',
      \ function('dapper#model#Model#receive', l:new))
  call a:message_passer.subscribe(
      \ 'ThreadsResponse',
      \ function('dapper#model#Model#receive', l:new))
  " let g:dapper_model = l:new
  return l:new
endfunction

function! dapper#model#Model#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Model')
  try
    let l:err = '(dapper#model#Model) Object is not of type Model: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#model#Model) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Prompt the Model to update its contents.
function! dapper#model#Model#update() abort dict
  call dapper#model#Model#CheckType(l:self)
  call l:self['_message_passer'].request(
      \ 'threads', {}, function('dapper#model#Model#receive', l:self))
endfunction

" RETURNS:  (dapper#model#Thread)   A thread with the requested ID.
" DETAILS:  May throw a `NotFound` exception if a matching thread isn't found.
" PARAM:    tid   (v:t_number)  The ID of the thread.
function! dapper#model#Model#thread(tid) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:running = l:self['_ids_to_running']
  if !has_key(l:running, a:tid)
    let l:stopped = l:self['_ids_to_stopped']
    if has_key(l:stopped, a:tid) | return l:stopped[a:tid] | endif
    throw 'ERROR(NotFound) (dapper#model#Model) No thread with ID: '.a:tid
  endif
  return l:running[a:tid]
endfunction

" RETURNS:  (v:t_dict)  Dictionary containing all requested threads.
" PARAM:  include_exited  (v:t_bool?)   Whether to *also* provide stopped
"     threads.
function! dapper#model#Model#threads(...) abort dict
  call dapper#model#Model#CheckType(l:self)
  let a:include_exited = get(a:000, 0, v:false)
  let l:to_return = copy(l:self['_ids_to_running'])  " shallow copy
  if !a:include_exited | return l:to_return | endif
  let l:exited = l:self['_ids_to_stopped']
  for [l:tid, l:thread] in items(l:exited)
    let l:to_return[l:tid] = l:thread
  endfor
  return l:to_return
endfunction

" BRIEF:  Handle incoming debug adapter protocol messages.
function! dapper#model#Model#receive(msg) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:typename = a:msg['vim_msg_typename']
  if l:typename ==# 'ThreadEvent'
    call l:self._reqThreads()
    call l:self._recvEvent(a:msg)
  elseif l:typename ==# 'StoppedEvent'
    call l:self._reqThreads()
  elseif l:typename ==# 'ThreadsResponse'
    call l:self._recvResponse(a:msg)
  else
    call l:self['_message_passer'].notifyReport(
        \ 'status',
        \ 'model#Model Received '.l:typename.', for some reason(?)',
        \ dapper#helpers#StrDump(a:msg)
        \ )
  endif
endfunction

" BRIEF:  Process an incoming ThreadEvent.
" PARAM:  event   (DebugProtocol.ThreadEvent)
function! dapper#model#Model#_recvEvent(event) abort dict
  call dapper#model#Model#CheckType(l:self)
  " make Thread object
  let l:body = a:event['body']
  let l:reason = l:body['reason']
  let l:long_msg = dapper#helpers#StrDump(l:body)
  if l:reason ==# 'started'
    call l:self._makeThread(l:body)
  elseif l:reason ==# 'exited'
    call l:self._archiveThread(l:body)
  else
    try
      let l:thread = l:self.thread(l:body['threadId'])
      call l:thread.updateProps(l:body)
    catch
    endtry
      let l:long_msg = 'Unrecognized reason: '.l:reason."\n".l:long_msg
  endif
  call l:self['_message_passer'].notifyReport(
      \ 'status',
      \ 'model#Model received ThreadEvent',
      \ l:long_msg
      \ )
endfunction

" BRIEF:  Process an incoming ThreadsResponse.
" PARAM:  response  (DebugProtocol.ThreadsResponse)
function! dapper#model#Model#_recvResponse(response) abort dict
  call dapper#model#Model#CheckType(l:self)
  if !a:response['success']
    call l:self['_message_passer'].notifyReport(
        \ 'error',
        \ 'model#Model ThreadsRequest failed outright!',
        \ dapper#helpers#StrDump(a:response),
        \ v:true)
    return
  endif
  let l:threads = a:response['body']['threads']
  let l:i = 0 | while l:i <# len(l:threads)
    let l:thread = l:threads[l:i]
    let l:tid = l:thread['id']
    let l:name = l:thread['name']
    let l:running = l:self['_ids_to_running']
    let l:stopped = l:self['_ids_to_stopped']
    if has_key(l:running, l:tid)
      call l:running[l:tid].update(l:thread)
    elseif has_key(l:stopped, l:tid)
      call l:stopped[l:tid].update(l:thread)
    else
      call l:self._makeThread(l:thread)
      let l:new_thread = l:self.thread(l:tid)
      call l:self['_message_passer'].notifyReport(
          \ 'error',
          \ 'model#Model received unknown Thread:'.l:tid
            \ . ', constructing from response.',
          \ dapper#helpers#StrDump(l:new_thread))
    endif
  let l:i += 1 | endwhile
endfunction

" BRIEF:  Add a new Thread object from the body of a ThreadEvent.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_makeThread(body) abort dict
  call dapper#model#Model#CheckType(l:self)

  let l:thread = dapper#model#Thread#new(
      \ a:body,
      \ l:self['_message_passer'])
  let l:self['_ids_to_running'][l:thread.id()] = l:thread

  call l:self['_message_passer'].notifyReport(
      \ 'status',
      \ 'model#Model constructed new Thread object.',
      \ dapper#helpers#StrDump(l:thread) )
endfunction

" BRIEF:  Process an exited Thread.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_archiveThread(body) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:tid = a:body['threadId']
  let l:brief = 'model#Model archived exited thread:'.l:tid
  let l:kind = 'status'
  let l:long_msg = ''
  try
    let l:thread = l:self['_ids_to_running'][l:tid]
    call l:thread.updateProps(a:body)
    unlet l:self['_ids_to_running'][l:tid]
    let l:self['_ids_to_stopped'][l:tid] = l:thread
    let l:long_msg = 'Thread archived.'
    " TODO: destroy older threads after this gets too large
  catch /ERROR(NotFound)/
    let l:brief = 'model#Model Unknown thread exited:'.l:tid
    let l:kind = 'error'
    let l:long_msg = 'Model state unchanged.'
  endtry
  call l:self['_message_passer'].notifyReport(
      \ l:kind,
      \ l:brief,
      \ l:long_msg )
endfunction

" BRIEF:  Request all active threads from the debug adapter.
function! dapper#model#Model#_reqThreads() abort dict
  call dapper#model#Model#CheckType(l:self)
  call l:self['_message_passer'].request(
      \ 'threads', {}, function('dapper#model#Model#receive', l:self))
endfunction
