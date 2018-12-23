" BRIEF:  Show active threads in the debuggee; 'drill down' into callstacks.

" BRIEF:  Construct a ThreadBuffer.
" PARAM:  bufname   (v:t_string)  The name to be displayed in the statusline.
function! dapper#ThreadBuffer#new(bufname) abort
  let l:new = dapper#DapperBuffer#new({'fname': a:bufname})
  let l:new['TYPE']['ThreadBuffer'] = 1

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
  " TODO make ThreadsRequest after receiving a ThreadEvent
  if l:reason ==# 'started'
    try
      " check for existing thread (i.e. if this ThreadEvent was just a 'bump'
      " from the debug adapter, rather than an actual new thread)
      let [l:start, l:end] = l:self.getRange(l:tid)
      call l:self.replaceLines(
        \ l:start-1,
        \ l:end,
        \ l:self.makeEntry(l:tid, 'unnamed', l:reason))
    catch /EntryNotFound/
      " insert at top
      call l:self.insertLines(0, l:self.makeEntry(l:tid, 'unnamed', l:reason))
    endtry
  elseif l:reason ==# 'exited'
    try
      let [l:start, l:end] = l:self.getRange(l:tid)
      call l:self.deleteLines(l:start, l:end)
      call l:self.insertLines(-1, l:self.makeEntry(l:tid, 'unnamed', ))
    catch /EntryNotFound/
      " TODO debug log?
    endtry
  else
    " TODO add thread, if it's new: return flag?
  endif
endfunction

" BRIEF:  Get the line range of a particular Thread entry.
function! dapper#ThreadBuffer#getRange(thread_id) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " TODO optimize this? (...it's surprisingly fast...)
  let l:entire_buffer = nvim_buf_get_lines(l:self['__bufnr'], 0, -1, v:false)
  let l:idx = match(l:entire_buffer, "thread\tid: ".a:thread_id)
  if l:idx ==# -1
    throw '(dapper#ThreadBuffer) EntryNotFound, thread_id:'.a:thread_id
  endif
  let l:idx += 1
  return [l:idx, l:idx]
endfunction

" BRIEF:  Set mappings to 'drill-down' into a Thread, expand info, etc.
function! dapper#ThreadBuffer#setMappings() abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " do nothing, for the time being
  " TODO
endfunction

" BRIEF:  Generate the text representing information about a Thread.
" RETURNS:  (v:t_list)  Line-by-line, the text representing the Thread.
" PARAM:  tid     (v:t_number)  A unique identifier for the thread.
" PARAM:  name    (v:t_string)  A name of the thread.
" PARAM:  status  (v:t_string)  The thread's status (exited, running, etc.)
function! dapper#ThreadBuffer#makeEntry(tid, name, status) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  " TODO refine
  return [printf("thread\tid: %d\tname: %s\tstatus: %s", a:tid, a:name, a:status)]
endfunction
