""
" @private
" @dict ThreadsBuffer
" Shows active threads in the debuggee; 'digs down' into callstacks.

let s:typename = 'ThreadsBuffer'
let s:thread_id_search_pat = '^thread id: '

""
" @dict ThreadsBuffer
" @function dapper#view#ThreadsBuffer#New()
" Construct a ThreadsBuffer using the given {model} (see @dict(Model)) and
" {message_passer} (see @dict(MiddleTalker)).
"
" @throws WrongType if {model} or {message_passer} aren't dictionaries.
function! dapper#view#ThreadsBuffer#New(model, message_passer) abort
  call maktaba#ensure#IsDict(a:model)
  call maktaba#ensure#IsDict(a:message_passer)
  let l:base = dapper#view#DapperBuffer#new(
      \ a:message_passer, {'fname': '[dapper.nvim] Threads'})

  let l:new = {
      \ '_ids_to_threads': {},
      \ '_model': a:model,
      \ 'Show': typevim#make#Member('Show'),
      \ 'Receive': typevim#make#Member('Receive'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'SetMappings': typevim#make#Member('SetMappings'),
      \ '_AddThreadEntry': typevim#make#Member('_AddThreadEntry'),
      \ '_UpdateThreads': typevim#make#Member('_UpdateThreads'),
      \ 'MakeEntry': typevim#make#Member('MakeEntry'),
      \ 'ClimbUp': typevim#make#Member('ClimbUp'),
      \ 'DigDown': typevim#make#Member('DigDown'),
      \ '_MakeChild': typevim#make#Member('_MakeChild'),
      \ '_GetSelected': typevim#make#Member('_GetSelected'),
      \ }

  call typevim#make#Derived(s:typename, l:base, l:new)

  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)

  " should update *after* the model has been updated
  call a:message_passer.Subscribe('StoppedEvent', l:new.Receive)
  call a:message_passer.Subscribe('ThreadEvent', l:new.Receive)
  call a:message_passer.Subscribe('ThreadsResponse', l:new.Receive)

  call l:new.replaceLines(0, -1, ['<threads>', '</threads>'])

  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict ThreadsBuffer
" Show the given list of {threads}.
function! dapper#view#ThreadsBuffer#Show(threads) abort dict
  call s:CheckType(l:self)
endfunction

""
" @dict ThredsBuffer
" Notify this ThreadsBuffer that it should update its listed threads from the
" given {msg}.
"
" @throws WrongType if the given {msg} is not a dict.
function! dapper#view#ThreadsBuffer#Receive(msg) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsDict(a:msg)
  if a:msg['type'] ==# 'response' && !a:msg['success'] | return | endif
  let l:model = l:self._model

  let l:body = a:msg.body
  let l:type = a:msg.vim_msg_typename
  if l:type ==# 'StoppedEvent'
    " update the full list
    let l:ids_to_threads = l:model.threads(1)  " all of them
    call l:self._UpdateThreads(l:ids_to_threads) " TODO test
  elseif l:type ==# 'ThreadEvent'
    let l:tid = l:body['threadId']
    let l:thread = l:model.thread(l:tid)
    let l:ids_to_threads = {}
    let l:ids_to_threads[l:tid] = l:thread
    call l:self._UpdateThreads(l:ids_to_threads)
  elseif l:type ==# 'ThreadsResponse'
    " TODO update thread entries mentioned in response
    let l:dap_threads = a:msg['body']['threads']
    let l:to_update = {}
    for l:dap_thread in l:dap_threads
      try
        let l:tid = l:dap_thread['id']
        let l:thread = l:model.Thread(l:tid)
        let l:to_update[l:tid] = l:thread
      catch
      endtry
    endfor
    call l:self._UpdateThreads(l:to_update)
  endif

  let l:self['_ids_to_threads'] = l:self['_model'].Threads()
endfunction

""
" @dict ThreadsBuffer
" Get the line range of the entry for the thread with the given {thread_id}.
"
" @throws NotFound if the given entry can't be found.
" @throws WrongType if {thread_id} isn't a number.
function! dapper#view#ThreadsBuffer#GetRange(thread_id) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsNumber(a:thread_id)
  " TODO optimize this? (...it's surprisingly fast...)
  let l:entire_buffer = nvim_buf_get_lines(l:self['__bufnr'], 0, -1, 0)
  let l:idx = match(l:entire_buffer, s:thread_id_search_pat.a:thread_id)
  if l:idx ==# -1
    throw maktaba#error#NotFound('Thread with id %s not found', a:thread_id)
  endif
  let l:idx += 1
  return [l:idx, l:idx]
endfunction

""
" @dict ThreadsBuffer
" Set mappings to 'drill-down' into a Thread, expand info, etc.
function! dapper#view#ThreadsBuffer#SetMappings() abort dict
  call s:CheckType(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#DigDownMapping().' '
      \ . ':call b:dapper_buffer.digDown()<cr>'
endfunction

""
" @dict ThreadsBuffer
" Add a new {thread} to the buffer, or replace/update the entry that's already
" there. If [add_at_top] is true, then if {thread} is a new entry, it will be
" added at the top of the buffer; if it's false, new entries will be added at
" the bottom.
"
" @default add_at_top=1
" @throws WrongType if {thread} is not a @dict(Thread) or [add_at_top] is not a boolean.
function! dapper#view#ThreadsBuffer#_AddThreadEntry(thread, ...) abort dict
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:thread, 'Thread')
  let l:add_at_top = typevim#ensure#IsBool(get(a:000, 0, 1))
  let l:tid    = a:thread.id()
  let l:name   = a:thread.name()
  let l:status = a:thread.status()
  let l:new_entry = l:self.MakeEntry(a:thread)
  try
    " replace existing entry
    let [l:start, l:end] = l:self.GetRange(l:tid)
      call l:self.ReplaceLines(
        \ l:start-1,
        \ l:end,
        \ l:new_entry)
    call l:self._Log(
        \ 'status',
        \ 'ThreadsBuffer updated thread ID:'.l:tid,
        \ l:new_entry)
  catch /EntryNotFound/
    let l:insert_after = (l:add_at_top) ? 1 : -2
    call l:self.InsertLines(l:insert_after, l:new_entry)
    call l:self._log(
        \ 'status',
        \ 'ThreadsBuffer added new thread ID:'.l:tid,
        \ l:new_entry)
  endtry
endfunction

""
" @dict ThreadsBuffer
" Update the contents of the buffer from the given {ids_to_threads}
" dictionary, a mapping between thread IDs and their corresponding
" @dict(Thread) objects.
function! dapper#view#ThreadsBuffer#_UpdateThreads(ids_to_threads) abort dict
  call s:CheckType(l:self)
  for [l:tid, l:thread] in items(a:ids_to_threads)
    let l:add_at_top = l:thread.status() !=# 'exited'
    call l:self._AddThreadEntry(l:thread, l:add_at_top)
  endfor
endfunction

""
" @dict ThreadsBuffer
" Generate the text representing {thread}. Returns a list of strings: the text
" representing the @dict(Thread).
"
" @throws WrongType if {thread} is not a @dict(Thread).
function! dapper#view#ThreadsBuffer#makeEntry(thread) abort dict
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:thread, 'Thread')
  let l:tid    = a:thread.id()
  let l:name   = a:thread.name()
  let l:status = a:thread.status()
  return [printf("thread id: %d\tname: %s\t\tstatus: %s", l:tid, l:name, l:status)]
endfunction


""
" @dict ThreadsBuffer
" Do nothing!
function! dapper#view#ThreadsBuffer#ClimbUp() abort dict
  call s:CheckType(l:self)
endfunction

""
" @dict ThreadsBuffer
" Examine the stack trace of the selected thread.
function! dapper#view#ThreadsBuffer#DigDown() abort dict
  call s:CheckType(l:self)
  let l:long_msg = ''
  try
    let l:tid = l:self._GetSelected()
  catch /ERROR(NotFound)/
    return
  endtry
  call l:self._log(
      \ 'status',
      \ 'Digging down from ThreadsBuffer to tid:'.l:tid,
      \ l:long_msg
      \ )
  call l:self._DigDownAndPush(l:self['_model'].thread(l:tid))
endfunction

""
" @dict ThreadsBuffer
" Construct a @dict(StackTraceBuffer) and mark it as this
" @dict(ThreadsBuffer)'s child.
function! dapper#view#ThreadsBuffer#_MakeChild() abort dict
  call s:CheckType(l:self)
  let l:child = dapper#view#StackTraceBuffer#New(l:self['_message_passer'])
  call l:child.SetParent(l:self)
  return l:child
endfunction

""
" @dict ThreadsBuffer
" Returns the ID of the thread over which theuser's cursor is hovering.
function! dapper#view#ThreadsBuffer#_GetSelected() abort dict
  call s:CheckType(l:self)
  let l:cur_line = line('.')
  if     l:cur_line ==# 1         | normal! j
  elseif l:cur_line ==# line('$') | normal! k
  endif
  let l:tid_line = search(s:thread_id_search_pat, 'bncW')
  if !l:tid_line
    call l:self._log('error', 'Couldn''t find a selected thread ID',
        \ 'curpos: '.string(getcurpos())."\nbuffer contents:\n".getline(1,'$'))
    throw '(dapper#view#ThreadsBuffer) No thread ID found'
  endif
  let l:tid = matchstr(getline(l:tid_line), '[0-9]*\(\tname\)\@=') + 0
  return l:tid
endfunction
