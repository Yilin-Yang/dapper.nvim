""
" @dict StackTraceBuffer
" Shows a thread's stack trace. Allows the user to "drill down" into
" particular stackframes, or back out into the parent @dict(ThreadsBuffer).

let s:plugin = maktaba#plugin#Get('dapper.nvim')

let s:typename = 'StackTraceBuffer'
let s:counter = 0

""
" @public
" @dict StackTraceBuffer
" @function dapper#view#StackTraceBuffer#New({message_passer}, [thread])
" Construct a StackTraceBuffer from a {message_passer} and, optionally, the
" @dict(Thread) object [thread]. If provided, StackTraceBuffer will associate
" with the given [thread] and display its stack trace.
"
" @default thread={}
"
" @throws BadValue if {message_passer} or [thread] are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if [thread] is nonempty and is not a @dict(Thread).
function! dapper#view#StackTraceBuffer#New(message_passer, ...) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:thread = get(a:000, 0, {})
  if !empty(l:thread) | call typevim#ensure#IsType(l:thread, 'Thread') | endif

  let l:base = dapper#view#DapperBuffer#new(
          \ a:message_passer,
          \ {'bufname': '[dapper.nvim] Stack Trace, '.s:counter})
  let s:counter += 1

  let l:new = {
      \ '_thread': l:thread,
      \ '_ResetBuffer': typevim#make#Member('_ResetBuffer'),
      \ 'thread': typevim#make#Member('thread'),
      \ 'Push': typevim#make#Member('Push'),
      \ '_PrintFailedResponse': typevim#make#Member('_PrintFailedResponse'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'SetMappings': typevim#make#Member('SetMappings'),
      \ 'ClimbUp': typevim#make#Member('ClimbUp'),
      \ 'DigDown': typevim#make#Member('DigDown'),
      \ '_MakeChild': typevim#make#Member('_MakeChild'),
      \ '_GetSelected': typevim#make#Member('_GetSelected'),
      \ '_ShowCallstack': typevim#make#Member('_ShowCallstack'),
      \ }
  call typevim#make#Derived(s:typename, l:base, l:new)
  let l:new._PrintFailedResponse =
      \ typevim#object#Bind(l:new._PrintFailedResponse, l:new)
  let l:new._ShowCallstack =
      \ typevim#object#Bind(l:new._ShowCallstack, l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict StackTraceBuffer
" Clear the contents of this buffer, leaving only a pair of opening and
" closing `"<stacktrace>"` tags.
function! dapper#view#StackTraceBuffer#_ResetBuffer() dict abort
  call s:CheckType(l:self)
  call l:self.ReplaceLines(1, -1, ['<stacktrace>', '</stacktrace>'])
endfunction

""
" @public
" @dict StackTraceBuffer
" Return the thread object whose callstack this buffer shows.
function! dapper#view#StackTraceBuffer#thread() dict abort
  call s:CheckType(l:self)
  return l:self._thread
endfunction

""
" @dict StackTraceBuffer
" Report that an attempt to retrieve a @dict(StackTrace) object failed.
function! dapper#view#StackTraceBuffer#_PrintFailedResponse(error) dict abort
  call s:CheckType(l:self)
  call l:self._Log(
      \ 'error',
      \ 'StackTrace object retrieval failed!',
      \ a:error,
      \ l:self)
endfunction

""
" @public
" @dict StackTraceBuffer
" Display the stack trace of the given thread. The buffer will update when the
" StackTraceResponse arrives from the debug adapter, or throw an appropriate
" error message if the request fails entirely.
"
" @throws BadValue if {thread} is not a dict.
" @throws WrongType if {thread} is not a @dict(Thread).
function! dapper#view#StackTraceBuffer#Push(thread) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:thread, 'Thread')
  let l:self._thread = a:thread
  let l:stack_trace_promise = a:thread.stackTrace()
  call l:stack_trace_promise.Then(
      \ l:self._ShowCallstack,
      \ l:self._PrintFailedResponse)
  call l:self._Log(
      \ 'info',
      \ 'Will print StackTraceResponse in this buffer',
      \ l:stack_trace_promise,
      \ l:self
      \ )
endfunction

""
" @public
" Return the line range of the stack frame with the given index.
"
" @throws BadValue if given a negative {index}.
" @throws NotFound if the given entry can't be found.
" @throws WrongType if {index} isn't a number.
function! dapper#view#StackTraceBuffer#GetRange(index) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsNumber(a:index)
  if a:index <# 0
    throw maktaba#error#BadValue(
        \ 'Gave a negative stackframe index: %d', a:index)
  endif
  let l:line = 2 + a:index
  let l:num_lines = l:self.NumLines()
  if l:line >=# l:num_lines
    throw maktaba#error#NotFound('Stackframe with index %d not found', a:index)
  endif
  return [l:line, l:line]
endfunction

function! dapper#view#StackTraceBuffer#SetMappings() dict abort
  call s:CheckType(l:self)
  call setbufvar(l:self.bufnr(), 'dapper_buffer', l:self)
  execute 'nnoremap <buffer> '.s:plugin.flags.climb_up_mapping.Get().' '
      \ . ':call b:dapper_buffer.ClimbUp()<cr>'
  execute 'nnoremap <buffer> '.s:plugin.flags.dig_down_mapping.Get().' '
      \ . ':call b:dapper_buffer.DigDown()<cr>'
endfunction

""
" @dict StackTraceBuffer
" Show the contents of the {stack_trace} in this buffer.
"
" @throws BadValue if {stack_trace} is not a dict.
" @throws WrongType if {stack_trace} is not a @dict(StackTrace).
function! dapper#view#StackTraceBuffer#_ShowCallstack(stack_trace) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:stack_trace, 'StackTrace')
  let l:frames = a:stack_trace.stackFrames()
  let l:lines = []
  " TODO dynamically-adjustable format string
  let l:format_str = "(%d)\t[%.2s]\t(l:%d, c:%d)\t%s"
  let l:i = 0 | while l:i <# len(l:frames)
    let l:frame = l:frames[l:i]
    let l:info = l:frame.name
    let l:type = 'normal'
    if has_key(l:frame, 'presentationHint')
      let l:type = l:info.presentationHint
    endif

    if     l:type ==# 'normal' | let l:prefix = 'NO'
    elseif l:type ==# 'label'  | let l:prefix = 'LA'
    elseif l:type ==# 'subtle' | let l:prefix = 'SU'
    endif

    let l:stack_frame_str = printf(
            \ l:format_str,
            \ l:i, l:prefix, l:frame.line, l:frame.column, l:frame.name)
    call add(l:lines, l:stack_frame_str)
  let l:i += 1 | endwhile

  call l:self._ResetBuffer()
  call l:self.InsertLines(1, l:lines)
endfunction

""
" @public
" @dict StackTraceBuffer
" Climb back up to a list of all threads.
function! dapper#view#StackTraceBuffer#ClimbUp() dict abort
  call s:CheckType(l:self)
  if empty(l:self._parent)
    call l:self._Log(
        \ 'warn',
        \ 'No parent ThreadsBuffer for this StackTraceBuffer!',
        \ l:self
        \ )
    return
  endif
  try
    call l:self._parent.Switch()
  catch /ERROR(NotFound)/
    call l:self._parent.Open()
  endtry
endfunction

""
" @public
" @dict StackTraceBuffer
" Open the given stack frame.
function! dapper#view#StackTraceBuffer#DigDown() dict abort
  call s:CheckType(l:self)
  let l:callstack = l:self._thread.stackTrace()
  call l:self._DigDownAndPush(l:callstack[l:self.GetRange()])
endfunction

""
" @dict StackTraceBuffer
" Make a VariablesBuffer representing a stack frame in this StackTraceBuffer.
function! dapper#view#StackTraceBuffer#_MakeChild() dict abort
  call s:CheckType(l:self)
  let l:child = dapper#view#VariablesBuffer#New()
  call l:child.SetParent(l:self)
  return l:child
endfunction

""
" @dict StackTraceBuffer
" Get the numerical index corresponding to the selected stack frame.
"
" @throws NotFound if the numerical index could not be determined.
function! dapper#view#StackTraceBuffer#_GetSelected() dict abort
  call s:CheckType(l:self)

  function! s:ReportNotFound() abort
    call l:self._Log(
        \ 'warn',
        \ 'Could not determine currently selected stackframe!',
        \ extend(['buffer contents:'], l:self.GetLines(1, -1)),
        \ string(getcurpos())
        \ )
  endfunction

  let l:buf_contents = l:self.GetLines(1, -1)
  let l:lineno = line('.')

  if len(l:buf_contents ==# 2)  " only tags, no actual stack frames
    call s:ReportNotFound()
    return
  endif

  let l:found = 0
  while !l:found
    let l:lineno = line('.')
    let l:line = l:buf_contents[l:lineno]
    let l:tokens = matchlist(l:line, '(\([0-9]\{-}\)) \[\(..\)\]')
    if l:lineno ==# 1
      normal! j
    elseif l:lineno ==# len(l:buf_contents)
      normal! k
    elseif len(l:tokens) <# 3
      throw maktaba#error#Failure(
          \ 'StackTraceBuffer failed to parse stackframe entry: %s, '
          \ . 'parsed into tokens: %s', l:line, string(l:tokens))
    elseif l:tokens[2] ==# 'LA'  " is label, i.e. not a real stack frame
      if l:lineno <=# 2  " nothing above this stack frame?
        call s:ReportNotFound()
        return
      endif
      " move cursor up by one line
      normal! k
    else
      let l:found = 1
    endif
  endwhile

  return l:tokens[1]
endfunction
