" BRIEF:  Stores information about a running (or stopped) thread.

" BRIEF:  Construct a new Thread object.
" PARAM:  props   (v:t_dict)  The body of a `ThreadEvent`. Can accept the
"     following properties:
"       - 'id' or 'threadId'
"       - 'name'
"       - 'reason'
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  debug_logger    (dapper#log#DebugLogger?)
function! dapper#model#Thread#new(props, message_passer, ...) abort
  let a:debug_logger = get(a:000, 0, dapper#log#DebugLogger#dummy())

  let l:tid = 0
  if has_key(a:props, 'id')
    let l:tid = a:props['id']
  elseif has_key(a:props, 'threadId')
    let l:tid = a:props['threadId']
  endif

  let l:new = {
      \ 'TYPE': {'Thread': 1},
      \ '_tid': l:tid,
      \ '_name': has_key(a:props, 'name') ? a:props['name'] : 'unnamed',
      \ '_status': has_key(a:props, 'reason') ? a:props['reason'] : '(N/A)',
      \ '_callstack': [],
      \ '_message_passer': a:message_passer,
      \ '_debug_logger': a:debug_logger,
      \ 'id': function('dapper#model#Thread#id'),
      \ 'name': function('dapper#model#Thread#name'),
      \ 'status': function('dapper#model#Thread#status'),
      \ 'frame': function('dapper#model#Thread#frame'),
      \ 'receive': function('dapper#model#Thread#receive'),
      \ 'updateProps': function('dapper#model#Thread#updateProps'),
      \ }
  return l:new
endfunction

function! dapper#model#Thread#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Thread')
  try
    let l:err = '(dapper#model#Thread) Object is not of type Thread: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#Thread) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#model#Thread#id() abort dict
  call dapper#model#Thread#CheckType(l:self)
  return l:self['_tid']
endfunction

function! dapper#model#Thread#name() abort dict
  call dapper#model#Thread#CheckType(l:self)
  return l:self['_name']
endfunction

function! dapper#model#Thread#status() abort dict
  call dapper#model#Thread#CheckType(l:self)
  return l:self['_status']
endfunction

" RETURNS:  (dapper#model#StackFrame)   The requested stack frame, if it could
"     be found. Throws an `ERROR(NotFound)` otherwise.
function! dapper#model#Thread#frame(idx) abort dict
  call dapper#model#Thread#CheckType(l:self)
  let l:callstack = l:self['_callstack']
  if a:idx <# 0 || a:idx ># len(l:callstack)
    throw 'ERROR(NotFound) (dapper#model#Thread) No StackFrame with idx: '.a:idx
  endif
  return l:callstack[a:idx]
endfunction

" BRIEF:  Process an incoming StackTraceResponse.
function! dapper#model#Thread#receive(msg) abort dict
  call dapper#model#Thread#CheckType(l:self)
  let l:self['_callstack'] = a:msg['body']['stackFrames']
  " call l:self.notify() " TODO
  " call l:self['_debug_logger'].notifyReport(
  "     \ ''
  "     \ )
endfunction

" BRIEF:  Update the properties of this Thread from the properties given.
" PARAM:  props   (v:t_dict)  The body of a `ThreadEvent`. Can accept the
"     following properties:
"       - 'id' or 'threadId'
"       - 'name'
"       - 'reason'
function! dapper#model#Thread#updateProps(props) abort dict
  call dapper#model#Thread#CheckType(l:self)
  if has_key(a:props, 'id')
    let l:self['_id'] = a:props['id']
  elseif has_key(a:props, 'threadId')
    let l:self['_id'] = a:props['threadId']
  endif
  if has_key(a:props, 'name')
    let l:self['_name'] = a:props['name']
  endif
  if has_key(a:props, 'reason')
    let l:self['_status'] = a:props['reason']
  endif
endfunction
