" BRIEF:  Show a thread's stack trace. 'Drill down' into stackframes.


" BRIEF:  Construct a StackTraceBuffer.
" PARAM:  thread  (dapper#model#Thread?)  Display the thread of this callstack.
function! dapper#view#StackTraceBuffer#new(message_passer, ...) abort
  let a:thread = get(a:000, 0, {'TYPE': {'Thread': 1}})
  call dapper#model#Thread#CheckType(a:thread)
  let l:new =
      \ dapper#view#DapperBuffer#new(
          \ a:message_passer, {'fname': '[dapper.nvim] Stack Trace, '})
  let l:new['TYPE']['StackTraceBuffer'] = 1

  let l:new['_thread'] = a:thread
  let l:new['thread'] = function('dapper#view#StackTraceBuffer#thread')

  let l:new['show']        = function('dapper#view#StackTraceBuffer#show')
  let l:new['getRange']    = function('dapper#view#StackTraceBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#StackTraceBuffer#setMappings')

  let l:new['digDown'] = function('dapper#view#StackTraceBuffer#digDown')
  let l:new['_makeChild'] = function('dapper#view#StackTraceBuffer#_makeChild')

  let l:new['_showCallstack'] =
      \ function('dapper#view#StackTraceBuffer#_showCallstack')

  return l:new
endfunction

function! dapper#view#StackTraceBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackTraceBuffer')
  try
    let l:err = '(dapper#view#StackTraceBuffer) Object is not of type StackTraceBuffer: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#view#StackTraceBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURNS:  (dapper#model#Thread) The thread whose callstack this buffer shows.
function! dapper#view#StackTraceBuffer#thread() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  return l:self['_thread']
endfunction

" BRIEF:  Display the stack trace of the given thread.
" DETAILS:  The buffer (and its `ScopeBuffer` children) will update when the
"     `StackTraceResponse` arrives from the debug adapter.
" PARAM:  thread  (dapper#model#Thread)
function! dapper#view#StackTraceBuffer#show(thread) abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  call dapper#model#Thread#CheckType(a:thread)
  let l:self['_thread'] = a:thread
  let l:stack_trace = a:thread.stackTrace()
  " TODO display stack trace
  call l:stack_trace.subscribe(
      \ function('dapper#view#StackTraceBuffer#_showCallstack', l:self))
endfunction

" RETURNS:  (v:t_number)  The index of the selected stack frame.
function! dapper#view#StackTraceBuffer#getRange() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  while 1  " grab a valid stack frame
    let l:line = getline('.')
    let l:tokens = matchlist(l:line, '(\([0-9]\{-}\)) \[\(..\)\]')
    if !empty(l:tokens) || len(l:tokens) <# 3
      throw 'ERROR(NotFound) (dapper#view#StackTraceBuffer) '
          \ . 'Could not get selected stackframe!'
    endif
    if l:tokens[2] ==# 'LA'  " is label, i.e. not a real stack frame
      if getpos('.')[1] ==# 1
        return  " invalid selection, do nothing
      endif
      normal! k
    endif
  endwhile
  let l:frame_idx = l:tokens[1]
  return l:frame_idx
endfunction

function! dapper#view#StackTraceBuffer#setMappings() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#ClimbUpMapping().' '
      \ . ':call b:dapper_buffer.climbUp()<cr>'
  execute 'nnoremap <buffer> '.dapper#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction

" BRIEF:  Show the contents of the stack trace in this buffer.
" PARAM:  stack_trace (dapper#model#StackTrace) The stack trace to display. *It
"     is assumed that this is already populated.*
function! dapper#view#StackTraceBuffer#_showCallstack(stack_trace) abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  let l:frames = a:stack_trace.frames()
  let l:lines = []
  " TODO dynamically-adjustable format string
  let l:format_str = '(%d) [%.2s]  (l:%d, c:%d)  %s'

  let l:i = 0
  for l:frame in l:frames
    let l:info = l:frame.about()
    let l:type = l:info['presentationHint']

    if     l:type ==# 'normal' | let l:prefix = 'NO'
    elseif l:type ==# 'label'  | let l:prefix = 'LA'
    elseif l:type ==# 'subtle' | let l:prefix = 'SU'
    endif

    call add(
        \ l:lines,
        \ printf(
            \ l:format_str,
            \ l:i, l:prefix, l:info['line'], l:info['column'], l:info['name']))
    let l:i += 1
  endfor

  call l:self.replaceLines(0, -1, l:lines)
endfunction

" BRIEF:  Open the given stack frame.
function! dapper#view#StackTraceBuffer#digDown() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  let l:callstack = l:self['_thread'].stackTrace()
  call l:self._digDownAndPush(l:callstack[l:self.getRange()])
endfunction

" RETURNS:  (dapper#view#VariablesBuffer)
function! dapper#view#StackTraceBuffer#_makeChild() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  " return dapper#view#VariablesBuffer#new()
endfunction
