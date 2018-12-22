" BRIEF:  Show active threads in the debuggee; 'drill down' into callstacks.

" BRIEF:  Construct a ThreadBuffer.
" PARAM:  bufname   (v:t_string)  The name to be displayed in the statusline.
function! dapper#ThreadBuffer#new(bufname) abort
  let l:new = dapper#DapperBuffer#new({'fname': a:bufname})

  let l:new['receive']     = function('dapper#ThreadBuffer#receive')
  let l:new['getRange']    = function('dapper#ThreadBuffer#getRange')
  let l:new['setMappings'] = function('dapper#ThreadBuffer#setMappings')

  let l:new['makeEntry'] = function('dapper#ThreadBuffer#makeEntry')

  return l:new
endfunction

function! dapper#ThreadBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'ThreadBuffer')
    throw '(dapper#ThreadBuffer) Object is not of type ThreadBuffer: ' . a:object
  endif
endfunction

" BRIEF:  Update this buffer's displayed contents with a ThreadEvent.
" PARAM:  msg   (DebugProtocol.ThreadEvent)
function! dapper#ThreadBuffer#receive(msg) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let l:body = a:msg['body']
  let l:reason = l:body['reason']
  let l:tid    = l:body['threadId']
  if l:reason ==# 'started'
    " TODO add thread
  elseif l:reason ==# 'exited'
    " TODO remove thread
  else
    " TODO add thread, if it's new: return flag?
  endif
endfunction

" BRIEF:  Get the line range of a particular Thread entry.
function! dapper#ThreadBuffer#getRange(thread_id) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " TODO get range
  " TODO throw EntryNotFound if thread not found
endfunction

" BRIEF:  Set mappings to 'drill-down' into a Thread, expand info, etc.
function! dapper#ThreadBuffer#setMappings() abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " TODO
endfunction

" BRIEF:  Generate the text representing information about a Thread.
" PARAM:  tid     (v:t_number)  A unique identifier for the thread.
" PARAM:  name    (v:t_string)  A name of the thread.
" PARAM:  status  (v:t_string)  The thread's status (exited, running, etc.)
function! dapper#ThreadBuffer#makeEntry(tid, name, status) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " TODO
endfunction
