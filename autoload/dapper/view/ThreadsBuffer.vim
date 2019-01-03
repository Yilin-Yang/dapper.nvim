" BRIEF:  Show active threads in the debuggee; 'dig down' into callstacks.
" DETAILS:  Emits the `Thread` that the user wants to dig into.

" BRIEF:  Construct a ThreadsBuffer.
" PARAM:  bufname (v:t_string)  The name to be displayed in the statusline.
" PARAM:  model   (dapper#model#Model)
" PARAM:  message_passer  (dapper#MiddleTalker?)
function! dapper#view#ThreadsBuffer#new(
    \ bufname, model, message_passer) abort
  let l:new = call(
      \ 'dapper#view#RabbitHole#new',
      \ [a:message_passer, a:bufname])
  let l:new['TYPE']['ThreadsBuffer'] = 1
  let l:new['_ids_to_threads'] = {}
  let l:new['_model'] = a:model  " reference to the global debug model

  let l:new['show']        = function('dapper#view#ThreadsBuffer#show')
  let l:new['receive']     = function('dapper#view#ThreadsBuffer#receive')
  let l:new['getRange']    = function('dapper#view#ThreadsBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#ThreadsBuffer#setMappings')

  let l:new['_addThreadEntry'] = function('dapper#view#ThreadsBuffer#_addThreadEntry')
  let l:new['_updateThreads'] = function('dapper#view#ThreadsBuffer#_updateThreads')
  let l:new['makeEntry'] = function('dapper#view#ThreadsBuffer#makeEntry')

  let l:new['climbUp'] = function('dapper#view#ThreadsBuffer#climbUp')
  let l:new['digDown'] = function('dapper#view#ThreadsBuffer#digDown')

  let l:new['_getSelected'] = function('dapper#view#ThreadsBuffer#_getSelected')

  " should update *after* the model has been updated
  call a:message_passer.subscribe('StoppedEvent',
      \ function('dapper#view#ThreadsBuffer#receive', l:new))
  call a:message_passer.subscribe('ThreadEvent',
      \ function('dapper#view#ThreadsBuffer#receive', l:new))
  call a:message_passer.subscribe('ThreadsResponse',
      \ function('dapper#view#ThreadsBuffer#receive', l:new))

  return l:new
endfunction

function! dapper#view#ThreadsBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ThreadsBuffer')
  try
    let l:err = '(dapper#view#ThreadsBuffer) Object is not of type ThreadsBuffer: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#view#ThreadsBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Show the given set of threads.
function! dapper#view#ThreadsBuffer#show(threads) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
endfunction

" BRIEF:  Notify this ThreadsBuffer that it should update its listed threads.
function! dapper#view#ThreadsBuffer#receive(msg) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  if a:msg['type'] ==# 'response' && !a:msg['success'] | return | endif
  let l:model = l:self['_model']

  let l:body = a:msg['body']
  let l:type = a:msg['vim_msg_typename']
  if l:type ==# 'StoppedEvent'
    " update the full list
    let l:ids_to_threads = l:model.threads(v:true)  " all of them
    call l:self._updateThreads(l:ids_to_threads) " TODO test
  elseif l:type ==# 'ThreadEvent'
    let l:tid = l:body['threadId']
    let l:thread = l:model.thread(l:tid)
    call l:self._updateThreads({l:tid: l:thread})
  elseif l:type ==# 'ThreadsResponse'
    " TODO update thread entries mentioned in response
    let l:dap_threads = a:msg['body']['threads']
    let l:to_update = {}
    for l:dap_thread in l:dap_threads
      try
        let l:tid = l:dap_thread['id']
        let l:thread = l:model.thread(l:tid)
        let l:to_update[l:tid] = l:thread
      catch
      endtry
    endfor
    call l:self._updateThreads(l:to_update)
  endif

  let l:self['_ids_to_threads'] = l:self['_model'].threads()
endfunction

" BRIEF:  Get the line range of a particular Thread entry.
function! dapper#view#ThreadsBuffer#getRange(thread_id) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  " TODO optimize this? (...it's surprisingly fast...)
  let l:entire_buffer = nvim_buf_get_lines(l:self['__bufnr'], 0, -1, v:false)
  let l:idx = match(l:entire_buffer, "thread\tid: ".a:thread_id)
  if l:idx ==# -1
    throw '(dapper#view#ThreadsBuffer) EntryNotFound, thread_id:'.a:thread_id
  endif
  let l:idx += 1
  return [l:idx, l:idx]
endfunction

" BRIEF:  Set mappings to 'drill-down' into a Thread, expand info, etc.
function! dapper#view#ThreadsBuffer#setMappings() abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction

" BRIEF:  Add a new Thread to the buffer, or replace/update what's there.
" PARAM:  thread  (dapper#model#Thread)
" PARAM:  add_at_top  (v:t_bool?) `v:true` if a new entry should be added at
"                                 the top of the buffer; `v:false` if it
"                                 should be appended to the bottom.
function! dapper#view#ThreadsBuffer#_addThreadEntry(thread, ...) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  let a:add_at_top = get(a:000, 0, v:true)
  let l:tid    = a:thread.id()
  let l:name   = a:thread.name()
  let l:status = a:thread.status()
  let l:new_entry = l:self.makeEntry(a:thread)
  try
    " replace existing entry
    let [l:start, l:end] = l:self.getRange(l:tid)
      call l:self.replaceLines(
        \ l:start-1,
        \ l:end,
        \ l:new_entry)
    call l:self._log(
        \ 'status',
        \ 'ThreadsBuffer updated thread ID:'.l:tid,
        \ l:new_entry)
  catch /EntryNotFound/
    let l:insert_after = (a:add_at_top) ? 0 : -1
    call l:self.insertLines(l:insert_after, l:new_entry)
    call l:self._log(
        \ 'status',
        \ 'ThreadsBuffer added new thread ID:'.l:tid,
        \ l:new_entry)
  endtry
endfunction

" BRIEF:  Update the contents of the buffer with the given threads.
function! dapper#view#ThreadsBuffer#_updateThreads(ids_to_threads) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  for [l:tid, l:thread] in items(a:ids_to_threads)
    let l:add_at_top = l:thread.status() !=# 'exited'
    call l:self._addThreadEntry(l:thread, l:add_at_top)
  endfor
endfunction

" BRIEF:  Generate the text representing a Thread, using cached info.
" RETURNS:  (v:t_list)  Line-by-line, the text representing the Thread.
" PARAM:  thread  (dapper#model#Thread) The thread object.
function! dapper#view#ThreadsBuffer#makeEntry(thread) abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  let l:tid    = a:thread.id()
  let l:name   = a:thread.name()
  let l:status = a:thread.status()
  return [printf("thread\tid: %d\tname: %s\tstatus: %s", l:tid, l:name, l:status)]
endfunction


" BRIEF:  Do nothing!
function! dapper#view#ThreadsBuffer#climbUp() abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
endfunction

" BRIEF:  Examine the stack trace of the selected thread.
function! dapper#view#ThreadsBuffer#digDown() abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
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
      \ 'Digging down from ThreadsBuffer to tid:'.l:tid,
      \ l:long_msg
      \ )
  call l:st_buf.update()
  call l:st_buf.open()
endfunction

" RETURNS:  (v:t_number)  The thread ID of the thread currently selected by
"                         the cursor.
function! dapper#view#ThreadsBuffer#_getSelected() abort dict
  call dapper#view#ThreadsBuffer#CheckType(l:self)
  let l:tid_line = search("^thread\tid: ", 'bncW')
  if !l:tid_line
    call l:self._log('error', 'Couldn''t find a selected thread ID',
        \ 'curpos: '.string(getcurpos())."\nbuffer contents:\n".getline(1,'$'))
    throw '(dapper#view#ThreadsBuffer) No thread ID found'
  endif
  let l:tid = matchstr(getline(l:tid_line), '[0-9]*\(\tname\)\@=') + 0
  return l:tid
endfunction
