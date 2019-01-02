" BRIEF:  Encapsulates the state of the debugging process.

" BRIEF:  Construct a new Model.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  debug_logger    (dapper#DebugLogger?)
function! dapper#model#Model#new(message_passer, ...) abort
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
      \ '_debug_logger': a:debug_logger,
      \ 'thread': function('dapper#model#Model#thread'),
      \ 'receive': function('dapper#model#Model#receive'),
      \ '_recvEvent': function('dapper#model#Model#_recvEvent'),
      \ '_recvResponse': function('dapper#model#Model#_recvResponse'),
      \ '_makeThread': function('dapper#model#Model#_makeThread'),
      \ '_archiveThread': function('dapper#model#Model#_archiveThread'),
      \ }
  call a:message_passer.subscribe(
      \ 'ThreadEvent',
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
    echo a:object
    redir end
    let l:err = '(dapper#model#Model) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
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

" BRIEF:  Handle incoming debug adapter protocol messages.
function! dapper#model#Model#receive(msg) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:typename = a:msg['vim_msg_typename']
  if l:typename ==# 'ThreadEvent'
    call l:self._recvEvent(a:msg)
  elseif l:typename ==# 'ThreadsResponse'
    call l:self._recvResponse(a:msg)
  else
    call l:self['_debug_logger'].notifyReport(
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
  call l:self['_debug_logger'].notifyReport(
      \ 'status',
      \ 'model#Model received ThreadEvent',
      \ l:long_msg
      \ )
endfunction

" BRIEF:  Process an incoming ThreadsResponse.
" PARAM:  response  (DebugProtocol.ThreadsResponse)
function! dapper#model#Model#_recvResponse(response) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:threads = a:response['body']['threads']
  let l:i = 0 | while l:i <# len(l:threads)
    let l:thread = l:threads[l:i]
    let l:tid = l:thread['id']
    let l:running = l:self['_ids_to_running']
    let l:stopped = l:self['_ids_to_stopped']
    if has_key(l:running, l:tid)
      call l:running[l:tid].updateProps(l:thread)
    elseif has_key(l:stopped, l:tid)
      call l:stopped[l:tid].updateProps(l:thread)
    else
      call l:self['_debug_logger'].notifyReport(
          \ 'error',
          \ 'model#Model received unknown Thread:'.l:tid,
          \ dapper#helpers#StrDump(l:thread))
    endif
  let l:i += 1 | endwhile
endfunction

" BRIEF:  Add a new Thread object from the body of a ThreadEvent.
" PARAM:  body  (DebugProtocol.ThreadEvent.body)
function! dapper#model#Model#_makeThread(body) abort dict
  call dapper#model#Model#CheckType(l:self)
  let l:thread = dapper#model#Thread#new(
      \ a:body,
      \ l:self['_message_passer'],
      \ l:self['_debug_logger'])
  " populate Thread asynchronously from ThreadsRequest
  call l:self['_message_passer'].request(
      \ 'threads', {}, function('dapper#model#Thread#receive', l:thread))
  let l:self['_ids_to_running'][l:thread.id()] = l:thread

  call l:self['_debug_logger'].notifyReport(
      \ 'status',
      \ 'model#Model constructed new Thread object.',
      \ dapper#helpers#StrDump(l:thread))
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
    let l:thread.updateProps(a:body)
    unlet l:self['_ids_to_running'][l:tid]
    let l:self['_ids_to_stopped'][l:tid] = l:thread
    let l:long_msg = 'Thread archived.'
    " TODO: destroy older threads after this gets too large
  catch /ERROR(NotFound)/
    let l:brief = 'model#Model Unknown thread exited:'.l:tid
    let l:kind = 'error'
    let l:long_msg = 'Model state unchanged.'
  endtry
  call l:self['_debug_logger'].notifyReport(
      \ l:kind,
      \ l:brief,
      \ l:long_msg )
endfunction
