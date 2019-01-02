" BRIEF:  Show active threads in the debuggee; 'drill down' into callstacks.

" BRIEF:  Construct a ThreadBuffer.
" PARAM:  bufname     (v:t_string)  The name to be displayed in the statusline.
function! dapper#view#ThreadBuffer#new(bufname, message_passer, ...) abort
  let l:new = call(
      \ 'dapper#view#RabbitHole#new',
      \ [a:message_passer, a:bufname] + a:000)
  let l:new['TYPE']['ThreadBuffer'] = 1
  let l:new['_ids_to_threads'] = dapper#view#ThreadsCache#new()
  let l:new['_tids_to_stbuffers'] = {}  " tid to StackTraceBuffer

  let l:new['receive']     = function('dapper#view#ThreadBuffer#receive')
  let l:new['update']      = function('dapper#view#ThreadBuffer#update')
  let l:new['getRange']    = function('dapper#view#ThreadBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#ThreadBuffer#setMappings')

  let l:new['_addThreadEntry'] = function('dapper#view#ThreadBuffer#_addThreadEntry')
  let l:new['_recvEvent'] = function('dapper#view#ThreadBuffer#_recvEvent')
  let l:new['_recvResponse'] = function('dapper#view#ThreadBuffer#_recvResponse')
  let l:new['makeEntry'] = function('dapper#view#ThreadBuffer#makeEntry')

  let l:new['climbUp'] = function('dapper#view#ThreadBuffer#climbUp')
  let l:new['digDown'] = function('dapper#view#ThreadBuffer#digDown')

  let l:new['_getSelected'] = function('dapper#view#ThreadBuffer#_getSelected')

  call l:new._subscribe('Thread',
      \ function('dapper#view#ThreadBuffer#receive', l:new))

  return l:new
endfunction

function! dapper#view#ThreadBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ThreadBuffer')
  try
    let l:err = '(dapper#view#ThreadBuffer) Object is not of type ThreadBuffer: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#view#ThreadBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Process an incoming ThreadEvent or ThreadsResponse.
" PARAM:  msg   (DebugProtocol.ThreadEvent|DebugProtocol.ThreadsResponse)
function! dapper#view#ThreadBuffer#receive(msg) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let l:typename = a:msg['vim_msg_typename']
  let l:long_msg =
      \ 'ThreadBuffer, bufnr:'.l:self.bufnr().', received message: '.l:typename
  if l:typename ==# 'ThreadEvent'
    " make ThreadsRequest
    call l:self._request('threads', {}, function('dapper#view#ThreadBuffer#receive', l:self))
    " update from ThreadEvent
    call l:self._recvEvent(a:msg)
  elseif l:typename ==# 'ThreadsResponse'
    call l:self._recvResponse(a:msg)
  endif
  call l:self._log(
      \ 'status',
      \ 'ThreadBuffer received '.l:typename,
      \ l:long_msg
      \ )
endfunction

" BRIEF:  Ask this ThreadBuffer to refresh its contents.
" DETAILS:  ThreadBuffer will request a list of running threads from the debug
"           adapter.
function! dapper#view#ThreadBuffer#update() abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  call l:self._request('threads', {}, function('dapper#view#ThreadBuffer#receive', l:self))
endfunction

" BRIEF:  Get the line range of a particular Thread entry.
function! dapper#view#ThreadBuffer#getRange(thread_id) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  " TODO optimize this? (...it's surprisingly fast...)
  let l:entire_buffer = nvim_buf_get_lines(l:self['__bufnr'], 0, -1, v:false)
  let l:idx = match(l:entire_buffer, "thread\tid: ".a:thread_id)
  if l:idx ==# -1
    throw '(dapper#view#ThreadBuffer) EntryNotFound, thread_id:'.a:thread_id
  endif
  let l:idx += 1
  return [l:idx, l:idx]
endfunction

" BRIEF:  Set mappings to 'drill-down' into a Thread, expand info, etc.
function! dapper#view#ThreadBuffer#setMappings() abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#view#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction

" BRIEF:  Add a new Thread to the buffer, or replace/update what's there.
" PARAM:  dap_thread  (dapper#view#Thread)
" PARAM:  add_at_top  (v:t_bool?) `v:true` if a new entry should be added at
"                                 the top of the buffer; `v:false` if it
"                                 should be appended to the bottom.
function! dapper#view#ThreadBuffer#_addThreadEntry(dap_thread, ...) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let a:add_at_top = get(a:000, 0, v:true)
  let l:dp = a:dap_thread
  let l:tid    = l:dp['id']
  let l:name   = l:dp['name']
  let l:status = l:dp['status']
  let l:new_entry = l:self.makeEntry(l:tid)
  try
    " replace existing entry
    let [l:start, l:end] = l:self.getRange(l:tid)
      call l:self.replaceLines(
        \ l:start-1,
        \ l:end,
        \ l:new_entry)
    call l:self._log(
        \ 'status',
        \ 'ThreadBuffer updated thread ID:'.l:tid,
        \ l:new_entry)
  catch /EntryNotFound/
    let l:insert_after = (a:add_at_top) ? 0 : -1
    call l:self.insertLines(l:insert_after, l:new_entry)
    call l:self._log(
        \ 'status',
        \ 'ThreadBuffer added new thread ID:'.l:tid,
        \ l:new_entry)
  endtry
endfunction

" BRIEF:  Handle an incoming ThreadEvent. Update internal Threads cache.
" PARAM:  thread_event  (DebugProtocol.ThreadEvent)
function! dapper#view#ThreadBuffer#_recvEvent(thread_event) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
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
function! dapper#view#ThreadBuffer#_recvResponse(thread_response) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let l:tlist = a:thread_response['body']['threads']
  for l:dp in l:tlist
    let l:thread = l:self['_ids_to_threads'].update(l:dp['id'], l:dp)
    call l:self._addThreadEntry(l:thread, v:true)
  endfor
endfunction

" BRIEF:  Generate the text representing a Thread, using cached info.
" RETURNS:  (v:t_list)  Line-by-line, the text representing the Thread.
" PARAM:  tid     (v:t_number)  A unique identifier for the thread.
function! dapper#view#ThreadBuffer#makeEntry(tid) abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let l:thread = l:self['_ids_to_threads'].get(a:tid)
  let a:name   = l:thread['name']
  let a:status = l:thread['status']
  return [printf("thread\tid: %d\tname: %s\tstatus: %s", a:tid, a:name, a:status)]
endfunction


" BRIEF:  Do nothing!
function! dapper#view#ThreadBuffer#climbUp() abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
endfunction

" BRIEF:  Examine the stack trace of the selected thread.
function! dapper#view#ThreadBuffer#digDown() abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let l:long_msg = ''
  try
    let l:tid = l:self._getSelected()
  catch /No thread ID found/
    return
  endtry
  let l:tids_stbf = l:self['_tids_to_stbuffers']
  if !has_key(l:tids_stbf, l:tid)
    let l:st_buf = dapper#view#StackTraceBuffer#new(
        \ l:self,
        \ l:tid,
        \ '[dapper.nvim] Callstack, tid: '.l:tid,
        \ l:self['___message_passer___'])
    let l:tids_stbf[l:tid] = l:st_buf
    let l:long_msg .= 'Constructed new StackTraceBuffer: '
        \ . dapper#view#helpers#StrDump(l:st_buf)
  else
    let l:st_buf = l:tids_stbf[l:tid]
    let l:long_msg .= 'Found existing StackTraceBuffer: '
        \ . dapper#view#helpers#StrDump(l:st_buf)
  endif
  call l:self._log(
      \ 'status',
      \ 'Digging down from ThreadBuffer to tid:'.l:tid,
      \ l:long_msg
      \ )
  call l:st_buf.update()
  call l:st_buf.open()
endfunction

" RETURNS:  (v:t_number)  The thread ID of the thread currently selected by
"                         the cursor.
function! dapper#view#ThreadBuffer#_getSelected() abort dict
  call dapper#view#ThreadBuffer#CheckType(l:self)
  let l:tid_line = search("^thread\tid: ", 'bncW')
  if !l:tid_line
    call l:self._log('error', 'Couldn''t find a selected thread ID',
        \ 'curpos: '.string(getcurpos())."\nbuffer contents:\n".getline(1,'$'))
    throw '(dapper#view#ThreadBuffer) No thread ID found'
  endif
  let l:tid = matchstr(getline(l:tid_line), '[0-9]*\(\tname\)\@=') + 0
  return l:tid
endfunction
