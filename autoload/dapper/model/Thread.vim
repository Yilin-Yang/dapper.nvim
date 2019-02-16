""
" @private
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
" @dict Thread
" @function dapper#model#Thread#New({props} {message_passer})
" Construct a new Thread object. Will automatically request its own stack
" trace on construction.
"
" {props} is the body of a ThreadEvent, which can contain the following
" properties:
" - "id" or "threadId", which are numbers.
" - "name", a string.
" - "reason", a string.
" @throws WrongType if the {props} don't have the above types, or if {message_passer} isn't a dict.
function! dapper#model#Thread#new(props, message_passer) abort
  call typevim#ensure#Implements(a:props, s:thread_event_body)
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  let l:tid = get(a:props, 'id', get(a:props, 'threadId', 0))
  let l:new = {
      \ '_tid': l:tid,
      \ '_name': get(a:props, 'name', 'unnamed'),
      \ '_status': get(a:props, 'reason', '(N/A)'),
      \ '_callstack': dapper#model#StackTrace#new(l:tid, a:message_passer),
      \ '_message_passer': a:message_passer,
      \ 'id': typevim#make#Member('id'),
      \ 'name': typevim#make#Member('name'),
      \ 'status': typevim#make#Member('status'),
      \ 'stackTrace': typevim#make#Member('stackTrace'),
      \ 'Update': typevim#make#Member('Update'),
      \ }

  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
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

""
" @dict Thread
" Returns a Promise that, when resolved, returns the thread's StackTrace.
function! dapper#model#Thread#stackTrace() abort dict
  call dapper#model#Thread#CheckType(l:self)
  let l:callstack = l:self._callstack
  if empty(l:callstack)
    let l:doer = dapper#RequestDoer#New(
        \ l:self._message_passer, 'stackTrace', {'threadId': l:self.id()})
    return typevim#Promise#New(l:doer)
  endif
  let l:to_return = typevim#Promise#New()
  call l:to_return.Resolve(l:callstack)
  return l:to_return
endfunction

""
" Update the properties of this Thread from {props}, which is the body of a
" ThreadEvent. {props} may contain the following properties:
" - 'id' or 'threadId'
" - 'name'
" - 'reason'
"
" If [update_stack_trace] is true, calling this function will prompt the Thread to update its cached stack trace.
function! dapper#model#Thread#Update(props, ...) abort dict
  call dapper#model#Thread#CheckType(l:self)
  let a:update_stack_trace = get(a:000, 0, 1)
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
  if a:update_stack_trace
    let l:self['_callstack'] =
        \ dapper#model#StackTrace#new(l:self['_id'], l:self['_message_passer'])
  endif
endfunction
