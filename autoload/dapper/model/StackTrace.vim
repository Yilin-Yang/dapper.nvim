""
" @dict StackTrace
" Stores a thread's callstack. Provides an interface to retrieve information
" about particular stack frames.

let s:typename = 'StackTrace'

""
" @public
" @function dapper#model#StackTrace#New({stack_trace_response}, {message_passer})
" @dict StackTrace
" Construct a new StackTrace object.
"
" @throws BadValue if {stack_trace_response} or {message_passer} are not dicts.
" @throws WrongType if {stack_trace_response} is not a StackTraceResponse, or if {message_passer} does not implement a @dict(MiddleTalker) interface.
function! dapper#model#StackTrace#New(stack_trace_response, message_passer) abort
  call typevim#ensure#Implements(
      \ a:stack_trace_response, dapper#dap#StackTraceResponse())
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  for l:stack_frame in a:stack_trace_response.body.stackFrames
    if typevim#value#Implements(l:stack_frame, dapper#dap#StackFrame())
      continue
    endif
    call a:message_passer.NotifyReport(
        \ 'error',
        \ 'Got malformed stack frame in callstack!',
        \ l:stack_frame,
        \ a:stack_trace_response
        \ )
    throw maktaba#error#Failure(
        \ 'Got bad stack frame in StackTraceResponse: %s',
        \ typevim#object#ShallowPrint(a:stack_trace_response))
  endfor
  let l:new = {
      \ '_response_body': a:stack_trace_response.body,
      \ '_indices_to_frames': {},
      \ '_message_passer': a:message_passer,
      \ 'totalFrames': typevim#make#Member('totalFrames'),
      \ 'stackFrames': typevim#make#Member('stackFrames'),
      \ 'frame': typevim#make#Member('frame'),
      \ 'Receive': typevim#make#Member('Receive')
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
" @dict StackTrace
" Returns the `totalFrames` value provided by the last-received
" StackTraceResponse.
function! dapper#model#StackTrace#totalFrames() dict abort
  call s:CheckType(l:self)
  return l:self._response_body.totalFrames
endfunction

""
" @public
" @dict StackTrace
" Returns the list of stack frames provided by the last-received
" StackTraceResponse.
function! dapper#model#StackTrace#stackFrames() dict abort
  call s:CheckType(l:self)
  return l:self._response_body.stackFrames
endfunction

""
" @public
" @dict StackTrace
" Returns a |TypeVim.Promise| that resolves to a @dict(StackFrame) object
" constructed from the stack frame at {index} in the callstack.
"
" @throws BadValue if {index} corresponds to an artificial "label" frame.
" @throws NotFound if {index} is out of range.
function! dapper#model#StackTrace#frame(index) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsNumber(a:index)
  if a:index >=# l:self.totalFrames()
    throw maktaba#error#NotFound(
        \ 'Stack frame index %d out of range (totalFrames is: %d)',
        \ a:index, l:self.totalFrames())
  endif
  let l:raw_frame = l:self._response_body.stackFrames[a:index]
  if l:raw_frame.presentationHint ==# 'label'
    throw maktaba#error#BadValue(
        \ 'Requested stack frame is a "label", not a real stack frame: %d',
        \ a:index)
  endif
  let l:indices_to_frames = l:self._indices_to_frames
  if has_key(l:indices_to_frames, a:index)
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(l:indices_to_frames[a:index])
    return l:to_return
  else
    let l:doer = dapper#RequestDoer#New(
        \ l:self._message_passer, 'scopes', {'frameId': l:raw_frame.id})
    let l:to_return = typevim#Promise#New(l:doer)
    call l:to_return.Then(l:self.Receive)
    return l:to_return
  endif
endfunction
