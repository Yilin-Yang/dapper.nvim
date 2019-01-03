" BRIEF:  Stores information about a running (or stopped) thread.

" BRIEF:  Construct a new Thread object.
" PARAM:  props   (v:t_dict)  The body of a `ThreadEvent`. Can accept the
"     following properties:
"       - 'id' or 'threadId'
"       - 'name'
"       - 'reason'
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#Thread#new(props, message_passer, ...) abort
  let l:new = call('dapper#Promise#new', a:000)

  let l:tid = 0
  if has_key(a:props, 'id')
    let l:tid = a:props['id']
  elseif has_key(a:props, 'threadId')
    let l:tid = a:props['threadId']
  endif

  let l:new['TYPE'] = {'Thread': 1}
  let l:new['_tid'] = l:tid
  let l:new['_name'] = has_key(a:props, 'name') ? a:props['name'] : 'unnamed'
  let l:new['_status'] = has_key(a:props, 'reason') ? a:props['reason'] : '(N/A)'
  let l:new['_callstack'] = dapper#model#StackTrace#new(l:tid, a:message_passer)
  let l:new['_message_passer'] = a:message_passer
  let l:new['id'] = function('dapper#model#Thread#id')
  let l:new['name'] = function('dapper#model#Thread#name')
  let l:new['status'] = function('dapper#model#Thread#status')
  let l:new['stackTrace'] = function('dapper#model#Thread#stackTrace')
  let l:new['receive'] = function('dapper#model#Thread#receive')
  let l:new['updateProps'] = function('dapper#model#Thread#updateProps')

  return l:new
endfunction

function! dapper#model#Thread#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Thread')
  try
    let l:err = '(dapper#model#Thread) Object is not of type Thread: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
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

" RETURNS:  (dapper#model#StackTrace)   The thread's StackTrace. Will throw an
"   `ERROR(NotFound)` if it has not yet been received.
function! dapper#model#Thread#stackTrace() abort dict
  call dapper#model#Thread#CheckType(l:self)
  let l:callstack = l:self['_callstack']
  if l:callstack ==# {}
    throw 'ERROR(NotFound) (dapper#model#Thread) No StackTrace found'
  endif
  return l:callstack
endfunction

" BRIEF:  Process an incoming StackTraceResponse.
function! dapper#model#Thread#receive(msg) abort dict
  call dapper#model#Thread#CheckType(l:self)
  let l:self['_callstack'] = a:msg['body']['stackFrames']
  call l:self['_message_passer'].notifyReport(
      \ 'status',
      \ 'model#Thread:'.l:self.id().' updated w/ stack trace',
      \ dapper#helpers#StrDump(a:msg)
      \ )
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
