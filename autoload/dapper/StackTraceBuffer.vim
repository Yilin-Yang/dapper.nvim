" BRIEF:  Show a thread's stack trace. 'Drill down' into stackframes.

" BRIEF:  Construct a StackTraceBuffer.
" PARAM:  parent      (dapper#DapperBuffer) The parent `ThreadBuffer`.
" PARAM:  bufname     (v:t_string)  The name to be displayed in the statusline.
function! dapper#StackTraceBuffer#new(parent, bufname, message_passer, ...) abort
  call dapper#DapperBuffer#CheckType(a:parent)
  let l:new = call(
      \ 'dapper#RabbitHole#new',
      \ [a:message_passer, a:bufname] + a:000)
  let l:new['TYPE']['StackTraceBuffer'] = 1
  let l:new['_parent'] = a:parent

  let l:new['receive']     = function('dapper#StackTraceBuffer#receive')
  let l:new['update']      = function('dapper#StackTraceBuffer#update')
  let l:new['getRange']    = function('dapper#StackTraceBuffer#getRange')
  let l:new['setMappings'] = function('dapper#StackTraceBuffer#setMappings')

  " let l:new['makeEntry'] = function('dapper#StackTraceBuffer#makeEntry')

  call l:new._subscribe(
      \ 'StackTrace',
      \ function('dapper#StackTraceBuffer#receive', l:new))
  return l:new
endfunction

function! dapper#StackTraceBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackTraceBuffer')
  try
    let l:err = '(dapper#StackTraceBuffer) Object is not of type StackTraceBuffer: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#StackTraceBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Process an incoming StackTraceResponse.
function! dapper#StackTraceBuffer#receive(msg) abort dict
  call dapper#StackTraceBuffer#CheckType(l:self)
endfunction

function! dapper#StackTraceBuffer#update() abort dict
  call dapper#StackTraceBuffer#CheckType(l:self)
endfunction

function! dapper#StackTraceBuffer#getRange() abort dict
  call dapper#StackTraceBuffer#CheckType(l:self)
endfunction

function! dapper#StackTraceBuffer#setMappings() abort dict
  call dapper#StackTraceBuffer#CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#ClimbUpMapping().' '
      \ . ':call b:dapper_buffer.climbUp()<cr>'
  execute 'nnoremap <buffer> '.dapper#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction
