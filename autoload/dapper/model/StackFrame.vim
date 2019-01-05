" BRIEF:  Represents a StackFrame, as returned by the debug adapter.
" DETAILS:  Shall be populated through a call to `StackFrame::receive` with a
"   an appropriate `ScopesRequest`.

" BRIEF:  Construct a new StackFrame object.
" PARAM:  frame_msg (DebugProtocol.StackFrame)  The information returned by
"     the debug adapter about this stack frame.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#StackFrame#new(frame_msg, message_passer, ...) abort
  let l:new = call('dapper#Promise#new', a:000)
  let l:new['TYPE']['StackFrame'] = 1

  let l:new['_message_passer'] = a:message_passer
  let l:new['_frame_msg'] = a:frame_msg
  let l:new['_scopes'] = {}
  let l:new['receive'] = function('dapper#model#StackFrame#receive')
  let l:new['scopes'] = function('dapper#model#StackFrame#scopes')
  let l:new['scope'] = function('dapper#model#StackFrame#scope')
  let l:new['about'] = function('dapper#model#StackFrame#about')

  call a:message_passer.request(
      \ 'scopes',
      \ {'frameId': a:frame_msg['id']},
      \ function('dapper#model#StackFrame#receive', l:new))

  return l:new
endfunction

function! dapper#model#StackFrame#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackFrame')
  try
    let l:err = '(dapper#model#StackFrame) Object is not of type StackFrame: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#model#StackFrame) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Populate this StackFrame and notify subscribers.
" PARAM:  msg   (DebugProtocol.ScopesResponse)
function! dapper#model#StackFrame#receive(msg) abort dict
  call dapper#model#StackFrame#CheckType(l:self)
  if !a:msg['success']
    call l:self.break(a:msg)
  endif
  let l:scopes = a:msg['body']['scopes']
  " TODO construct, populate Scopes
  " let l:self['_scopes'] =
  call l:self.fulfill(l:self)
endfunction

" RETURNS:  (v:t_dict)  A dictionary of scope names to all `dapper#model#Scope`
"     objects currently held by this `StackFrame` object.
function! dapper#model#StackFrame#scopes() abort dict
  call dapper#model#StackFrame#CheckType(l:self)
  return l:self['_scopes']
endfunction

" RETURNS:  (dapper#model#Scope)  The Scope with the requested name.
" DETAILS:  Throws an `ERROR(NotFound)` if a matching Scope could not be found.
function! dapper#model#StackFrame#scope(scope_name) abort dict
  call dapper#model#StackFrame#CheckType(l:self)
  if type(a:scope_name) !=# v:t_string
    throw 'ERROR(WrongType) (dapper#model#StackFrame) Bad argument to scope():'
        \ . dapper#helpers#StrDump(a:scope_name)
  endif
  if !has_key(l:self['_scopes'], a:scope_name)
    throw 'ERROR(NotFound) (dapper#model#StackFrame) Scope not found: '.a:scope
  endif
  return l:self['_scopes'][a:scope_name]
endfunction

" RETURNS:  (DebugProtocol.StackFrame)  Basic information about this StackFrame.
" DETAILS:  All properties will be populated: optional properties will be set
"     to the following 'default values':
"     - source:     {}  " empty dict
"     - endLine:    line
"     - endColumn:  column
"     - moduleId:   ''
"     - presentationHint: 'normal'
function! dapper#model#StackFrame#about() abort dict
  call dapper#model#StackFrame#CheckType(l:self)
  let l:info = l:self['_frame_msg']
  if !has_key(l:info, 'source')  | l:info['source']  = {}             | endif
  if !has_key(l:info, 'endLine') | l:info['endLine'] = l:info['line'] | endif
  if !has_key(l:info, 'endColumn')
    l:info['endColumn'] = l:info['endColumn']
  endif
  if !has_key(l:info, 'moduleId')
    l:info['moduleId'] = ''
  endif
  return l:info
endfunction
