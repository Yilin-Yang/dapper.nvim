" BRIEF:  Show active threads in the debuggee; 'drill down' into callstacks.

" BRIEF:  Construct a ThreadBuffer.
" PARAM:  bufname     (v:t_string)  The name to be displayed in the statusline.
function! dapper#ThreadBuffer#new(bufname, message_passer, ...) abort
  let l:new = dapper#DapperBuffer#new(a:message_passer, {'fname': a:bufname})
  let l:new['TYPE']['ThreadBuffer'] = 1
  let l:new['_ids_to_threads'] = dapper#ThreadsCache#new()

  let l:new['receive']     = function('dapper#ThreadBuffer#receive')
  let l:new['update']      = function('dapper#ThreadBuffer#update')
  let l:new['getRange']    = function('dapper#ThreadBuffer#getRange')
  let l:new['setMappings'] = function('dapper#ThreadBuffer#setMappings')

  let l:new['_addThreadEntry'] = function('dapper#ThreadBuffer#_addThreadEntry')
  let l:new['_recvEvent'] = function('dapper#ThreadBuffer#_recvEvent')
  let l:new['_recvResponse'] = function('dapper#ThreadBuffer#_recvResponse')
  let l:new['makeEntry'] = function('dapper#ThreadBuffer#makeEntry')

  call l:new._subscribe('Thread', function('dapper#ThreadBuffer#receive', l:new))
  return l:new
endfunction

function! dapper#ThreadBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ThreadBuffer')
  try
    let l:err = '(dapper#ThreadBuffer) Object is not of type ThreadBuffer: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#ThreadBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Process an incoming ThreadEvent.
" PARAM:  msg   (DebugProtocol.ThreadEvent)
function! dapper#ThreadBuffer#receive(msg) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let l:typename = a:msg['vim_msg_typename']
  if l:typename ==# 'ThreadEvent'
    " make ThreadsRequest
    call l:self._request('threads', {}, function('dapper#ThreadBuffer#receive', l:self))
    " update from ThreadEvent
    call l:self._recvEvent(a:msg)
  elseif l:typename ==# 'ThreadsResponse'
    call l:self._recvResponse(a:msg)
  endif
endfunction

" BRIEF:  Ask this ThreadBuffer to refresh its contents.
" DETAILS:  ThreadBuffer will request a list of running threads from the debug
"           adapter.
function! dapper#ThreadBuffer#update() abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  call l:self._request('threads', {}, function('dapper#ThreadBuffer#receive', l:self))
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

" BRIEF:  Add a new Thread to the buffer, or replace/update what's there.
" PARAM:  dap_thread  (dapper#Thread)
" PARAM:  add_at_top  (v:t_bool?) `v:true` if a new entry should be added at
"                                 the top of the buffer; `v:false` if it
"                                 should be appended to the bottom.
function! dapper#ThreadBuffer#_addThreadEntry(dap_thread, ...) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let a:add_at_top = get(a:000, 0, v:true)
  let l:dp = a:dap_thread
  let l:tid    = l:dp['id']
  let l:name   = l:dp['name']
  let l:status = l:dp['status']
  try
    " replace existing entry
    let [l:start, l:end] = l:self.getRange(l:tid)
      call l:self.replaceLines(
        \ l:start-1,
        \ l:end,
        \ l:self.makeEntry(l:tid))
  catch /EntryNotFound/
    let l:insert_after = (a:add_at_top) ? 0 : -1
    call l:self.insertLines(l:insert_after, l:self.makeEntry(l:tid))
  endtry
endfunction

" BRIEF:  Handle an incoming ThreadEvent. Update internal Threads cache.
" PARAM:  thread_event  (DebugProtocol.ThreadEvent)
function! dapper#ThreadBuffer#_recvEvent(thread_event) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let l:body = a:thread_event['body']
  let l:reason = l:body['reason']
  let l:tid    = l:body['threadId']
  let l:new_thread =
    \ l:self['_ids_to_threads'].update(l:tid, {'id': l:tid, 'status': l:reason})
  if l:reason ==# 'started'
    call l:self._addThreadEntry(l:new_thread, v:true)
  elseif l:reason ==# 'exited'
    call l:self._addThreadEntry(l:new_thread, v:false)
  else
    " TODO debug log?
    call l:self._addThreadEntry(l:new_thread, v:true)
  endif
endfunction

" BRIEF:  Update Threads cache; update the existing entry in the buffer.
" PARAM:  thread_response  (DebugProtocol.ThreadResponse)
function! dapper#ThreadBuffer#_recvResponse(thread_response) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let l:tlist = a:thread_response['body']['threads']
  for l:dp in l:tlist
    let l:thread = l:self['_ids_to_threads'].update(l:dp['id'], l:dp)
    call l:self._addThreadEntry(l:thread, v:true)
  endfor
endfunction

" BRIEF:  Generate the text representing a Thread, using cached info.
" RETURNS:  (v:t_list)  Line-by-line, the text representing the Thread.
" PARAM:  tid     (v:t_number)  A unique identifier for the thread.
function! dapper#ThreadBuffer#makeEntry(tid) abort dict
  call dapper#ThreadBuffer#CheckType(l:self)
  let l:thread = l:self['_ids_to_threads'].get(a:tid)
  let a:name   = l:thread['name']
  let a:status = l:thread['status']
  return [printf("thread\tid: %d\tname: %s\tstatus: %s", a:tid, a:name, a:status)]
endfunction
