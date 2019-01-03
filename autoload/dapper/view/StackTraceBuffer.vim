" BRIEF:  Show a thread's stack trace. 'Drill down' into stackframes.


" BRIEF:  Construct a StackTraceBuffer.
" PARAM:  parent      (dapper#view#DapperBuffer) The parent `ThreadBuffer`.
" PARAM:  thread_id   (v:t_number)  The thread ID this stacktrace represents.
" PARAM:  bufname     (v:t_string)  The name to be displayed in the statusline.
function! dapper#view#StackTraceBuffer#new(
    \ parent, thread_id, bufname, message_passer, ...) abort
  call dapper#view#DapperBuffer#CheckType(a:parent)
  let l:new = call(
      \ 'dapper#view#RabbitHole#new',
      \ [a:message_passer, a:bufname] + a:000)
  let l:new['TYPE']['StackTraceBuffer'] = 1
  let l:new['_parent'] = a:parent

  let l:st_args = deepcopy(s:stack_trace_args)
    let l:st_args['threadId']: a:thread_id
  let l:new['_st_args'] = l:st_args

  let l:new['receive']     = function('dapper#view#StackTraceBuffer#receive')
  let l:new['update']      = function('dapper#view#StackTraceBuffer#update')
  let l:new['getRange']    = function('dapper#view#StackTraceBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#StackTraceBuffer#setMappings')

  let l:new['climbUp'] = function('dapper#view#StackTraceBuffer#climbUp')
  let l:new['digDown'] = function('dapper#view#StackTraceBuffer#digDown')

  call l:new._subscribe(
      \ 'StackTrace',
      \ function('dapper#view#StackTraceBuffer#receive', l:new))

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

" BRIEF:  Process an incoming StackTraceResponse.
function! dapper#view#StackTraceBuffer#receive(msg) abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  if !a:msg['success']
    call l:self._log(
        \ 'error',
        \ 'StackTraceRequest failed!',
        \ has_key(a:msg, 'message') ? a:msg['message'] : '',
        \ has_key(a:msg, 'body')    ? a:msg['body']    : '' )
  endif
  try
    let l:resp = a:msg['body']  " StackTraceResponse
    let l:frames = l:resp['stackFrames']
    let l:i  = 0 | while l:i <# len(l:frames)
      let l:stack_frame = l:frames[l:i]

    let l:i += 1 | endwhile
  catch
    call l:self._log(
        \ 'error',
        \ 'Failed to process StackTraceResponse!',
        \ v:exception,
        \ v:throwpoint
        \ )
  endtry
  " TODO
  " clear buffer contents
  " destroy scopes children
  " format and display stackframes
  " create scopes children, also send async requests for all of them(?)
endfunction

" BRIEF:  Send a `StackTraceRequest`.
" DETAILS:  The buffer (and its `ScopeBuffer` children) will update when the
"     `StackTraceResponse` arrives from the debug adapter.
function! dapper#view#StackTraceBuffer#update() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  let l:args = l:self['_st_args']
  call l:self._request(
      \ 'stackTrace', l:args,
      \ function('dapper#view#StackTraceBuffer#receive', l:self))
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

function! dapper#view#StackTraceBuffer#climbUp() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
  call l:self['_parent'].open()
endfunction

function! dapper#view#StackTraceBuffer#digDown() abort dict
  call dapper#view#StackTraceBuffer#CheckType(l:self)
endfunction
