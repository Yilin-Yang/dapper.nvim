" BRIEF:  Show a thread's stack trace. 'Drill down' into stackframes.


" BRIEF:  Construct a StackTraceBuffer.
function! dapper#view#StackTraceBuffer#new(message_passer) abort
  let l:new =
      \ dapper#view#DapperBuffer#new(
          \ a:message_passer, {'fname': '[dapper.nvim] Stack Trace, '})
  let l:new['TYPE']['StackTraceBuffer'] = 1

  let l:st_args = deepcopy(s:stack_trace_args)
  let l:new['_st_args'] = l:st_args

  let l:new['show']        = function('dapper#view#ThreadsBuffer#show')
  let l:new['getRange']    = function('dapper#view#StackTraceBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#StackTraceBuffer#setMappings')

  let l:new['climbUp'] = function('dapper#view#StackTraceBuffer#climbUp')
  let l:new['digDown'] = function('dapper#view#StackTraceBuffer#digDown')

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

" BRIEF:  Display the stack trace of the given thread.
" DETAILS:  The buffer (and its `ScopeBuffer` children) will update when the
"     `StackTraceResponse` arrives from the debug adapter.
" PARAM:  thread  (dapper#model#Thread)
function! dapper#view#StackTraceBuffer#show(thread) abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  call dapper#model#Thread#CheckType(a:thread)
  let l:stack_trace = a:thread.stackTrace()
  " TODO display stack trace
  " call l:stack_trace.subscribe(
  "     \ function('dapper#view#StackTraceBuffer#_showCallstack', l:self))
endfunction

function! dapper#view#StackTraceBuffer#getRange() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
endfunction

function! dapper#view#StackTraceBuffer#setMappings() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#ClimbUpMapping().' '
      \ . ':call b:dapper_buffer.climbUp()<cr>'
  execute 'nnoremap <buffer> '.dapper#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction

" BRIEF:  Show the contents of the stack trace in this buffer.
function! dapper#view#StackTraceBuffer#_showCallstack(stack_trace) abort dict
endfunction

function! dapper#view#StackTraceBuffer#climbUp() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  call l:self['_parent'].open()
endfunction

function! dapper#view#StackTraceBuffer#digDown() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
endfunction
