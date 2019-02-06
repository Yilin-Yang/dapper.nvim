" BRIEF:  Represents a stack trace returned by the debug adapter.

" BRIEF:  Global StackFrameFormat, sent to the debug adapter.
let s:stack_frame_format = {
    \ 'hex': 0,
    \ 'parameters': 1,
    \ 'parameterTypes': 1,
    \ 'parameterNames': 1,
    \ 'parameterValues': 1,
    \ 'line': 1,
    \ 'module': 1,
    \ 'includeAll': 0,
    \ }

" BRIEF:  Initial `StackTraceArguments`.
" DETAILS:  - `startFrame = 0`: start from frame with index 0
"           - `levels = 0`: return all stack frames
"           - `format`: use given formatting parameters
let s:stack_trace_args = {
    \ 'threadId': 0,
    \ }
    " \ 'startFrame': 0,
    " \ 'levels': 0,
    " \ 'format': s:stack_frame_format,

" BRIEF:  Construct a StackTrace, doing something after construction completes.
" DETAILS:  Should be populated with a `DebugProtocol.StackTraceResponse`,
"   either by making a `DebugProtocol.StackTraceRequest` with `l:new.receive`
"   as the callback, or by directly calling `l:new.receive` with a manually
"   populated `StackTraceResponse`.
" PARAM:  thread_id   (v:t_number)
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#StackTrace#new(thread_id, message_passer, ...) abort
  let l:new = call('dapper#Promise#new', a:000)
  let l:new['TYPE']['StackTrace'] = 1
  let l:new['_message_passer'] = a:message_passer
  let l:new['_thread_id'] = a:thread_id
  let l:new['_stack_trace'] = []
  let l:new['Receive'] = function('dapper#model#StackTrace#Receive')
  let l:new['frame'] = function('dapper#model#StackTrace#frame')
  let l:new['frames'] = function('dapper#model#StackTrace#frames')
  let l:new['id'] = function('dapper#model#StackTrace#id')

  let l:args = deepcopy(s:stack_trace_args)
  let l:args['threadId'] = a:thread_id
  call a:message_passer.Request(
      \ 'stackTrace',
      \ l:args,
      \ function('dapper#model#StackTrace#Receive', l:new))

  return l:new
endfunction

function! dapper#model#StackTrace#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackTrace')
  try
    let l:err = '(dapper#model#StackTrace) Object is not of type StackTrace: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#model#StackTrace) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Populate this StackTrace and notify subscribers.
" PARAM:  msg   (DebugProtocol.StackTraceResponse)
function! dapper#model#StackTrace#Receive(msg) abort dict
  call dapper#model#StackTrace#CheckType(l:self)
  if !a:msg['success']
    call l:self['_message_passer'].NotifyReport(
        \ 'error', '(model#StackTrace) Request failed.',
        \ typevim#object#ShallowPrint(a:msg))
    call l:self.break(a:msg)
  endif
  call l:self['_message_passer'].NotifyReport(
      \ 'status', '(model#StackTrace) Received StackTraceResponse.',
      \ typevim#object#ShallowPrint(a:msg))

  let l:frames = a:msg['body']['stackFrames']
  let l:populated = l:self['_stack_trace']

  " construct StackFrame objects, populated with Scopes
  let l:msg_passer = l:self['_message_passer']
  let l:i = 0 | while l:i <# len(l:frames)
    let l:fr = l:frames[l:i]
    let l:new = dapper#model#StackFrame#new(l:fr, l:msg_passer)
    let l:populated += [l:new]
  let l:i += 1 | endwhile

  call l:self.fulfill(l:self)
endfunction

" RETURNS:  (dapper#model#StackFrame)   The StackFrame with the requested
"     index in the callstack.
" DETAILS:  Throws an `ERROR(NotFound)` if the given StackFrame could not be
"     found.
function! dapper#model#StackTrace#frame(idx) abort dict
  call dapper#model#StackTrace#CheckType(l:self)
  if type(a:idx) !=# v:t_number
    throw 'ERROR(WrongType) (dapper#model#StackTrace) Index isn''t number:'
        \ . typevim#object#ShallowPrint(a:idx)
  endif
  if a:idx >=# len(l:self['_stack_trace']) || a:idx <# 0
    throw 'ERROR(NotFound) (dapper#model#StackTrace) Frame not found at index: '
        \ . a:idx
  endif
  return l:self['_stack_trace'][a:idx]
endfunction

" RETURNS:  (v:t_list)  A list of all `dapper#model#StackFrame`s in this object.
function! dapper#model#StackTrace#frames() abort dict
  call dapper#model#StackTrace#CheckType(l:self)
  return l:self['_stack_trace']
endfunction

function! dapper#model#StackTrace#id() abort dict
  call dapper#model#StackTrace#CheckType(l:self)
  return l:self['_thread_id']
endfunction
