""
" @dict ThreadsBuffer
" Shows active threads in the debuggee; 'digs down' into callstacks.

let s:plugin = maktaba#plugin#Get('dapper.nvim')

let s:typename = 'ThreadsBuffer'
let s:thread_id_search_pat = '^thread id: '

""
" @public
" @dict ThreadsBuffer
" @function dapper#view#ThreadsBuffer#New({model} {message_passer})
" Construct a ThreadsBuffer using the given {model} (see @dict(Model)) and
" {message_passer} (see @dict(MiddleTalker)).
"
" @throws BadValue if {model} or {message_passer} aren't dicts.
" @throws WrongType if {model} or {message_passer} don't implement a @dict{Model} or @dict{MiddleTalker} interface, respectively.
function! dapper#view#ThreadsBuffer#New(model, message_passer) abort
  call typevim#ensure#Implements(
      \ a:model, dapper#model#Model#Interface())
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())

  let l:base = dapper#view#DapperBuffer#new(
      \ a:message_passer, {'bufname': '[dapper.nvim] Threads'})
  let l:new = {
      \ '_ids_to_threads': {},
      \ '_model': a:model,
      \ '_ResetBuffer': typevim#make#Member('_ResetBuffer'),
      \ '_AppendEntry': typevim#make#Member('_AppendEntry'),
      \ '_PrependEntry': typevim#make#Member('_PrependEntry'),
      \ 'Push': typevim#make#Member('Push'),
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
  call a:model.AddChild(l:new)
  call l:new._ResetBuffer()
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict ThreadsBuffer
" Replace the full contents of the buffer with the `"<threads>"`,
" `"</threads>"` tags.
function! dapper#view#ThreadsBuffer#_ResetBuffer() dict abort
  call s:CheckType(l:self)
  call l:self.ReplaceLines(1, -1, ['<threads>', '</threads>'])
endfunction

""
" @dict ThreadsBuffer
" Print an entry for the given {thread} at the end of the buffer, before the
" final `"</threads>"`.
"
" @throws BadValue if {thread} is not a dict.
" @throws WrongType if {thread} is not a @dict(Thread).
function! dapper#view#ThreadsBuffer#_AppendEntry(thread) dict abort
  call l:self.InsertLines(-2, l:self.MakeEntry(a:thread))
endfunction

""
" @dict ThreadsBuffer
" Print an entry for the given {thread} at the start of the buffer, after the
" initial `"<threads>"`.
"
" @throws BadValue if {thread} is not a dict.
" @throws WrongType if {thread} is not a @dict(Thread).
function! dapper#view#ThreadsBuffer#_PrependEntry(thread) dict abort
  call l:self.InsertLines(1, l:self.MakeEntry(a:thread))
endfunction

""
" @public
" @dict ThreadsBuffer
" Show the given list of {threads}. If given a @dict(Thread) [to_highlight],
" show that at the top of the buffer.
"
" @throws BadValue if [to_highlight] is provided and is not a dict.
" @throws WrongType if {threads} is not a dict, or if [to_highlight] is
" provided and is not a @dict(Thread).
function! dapper#view#ThreadsBuffer#Push(threads, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsDict(a:threads)
  let l:to_highlight = get(a:000, 0, v:null)

  call l:self._ResetBuffer()

  let l:ids_and_threads = sort(items(a:threads))
  let l:ids_and_exited  = []
  if l:to_highlight isnot v:null
    call l:self._PrependEntry(l:to_highlight)
    " remove from the list of threads so that we don't double-print
    let l:id = l:to_highlight.id()
    let l:i = 0 | while l:i <# len(l:ids_and_threads)
      if l:ids_and_threads[l:i][0] ==# l:id
        unlet l:ids_and_threads[l:i]
      endif
    let l:i += 1 | endwhile
  endif


  for [l:tid, l:thread] in l:ids_and_threads
    if l:thread.status() ==# 'exited'
      call add(l:ids_and_exited, [l:tid, l:thread])
      continue
    endif
    call l:self._AppendEntry(l:thread)
  endfor

  for [l:tid, l:thread] in l:ids_and_exited
    call l:self._AppendEntry(l:thread)
  endfor
endfunction

""
" @dict ThreadsBuffer
" Get the line range of the entry for the thread with the given {thread_id}.
"
" @throws NotFound if the given entry can't be found.
" @throws WrongType if {thread_id} isn't a number.
function! dapper#view#ThreadsBuffer#GetRange(thread_id) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsNumber(a:thread_id)
  let l:entire_buffer = l:self.GetLines(1, -1)
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
function! dapper#view#ThreadsBuffer#SetMappings() dict abort
  call s:CheckType(l:self)
  execute 'nnoremap <buffer> '.s:plugin.flags.dig_down_mapping.Get().' '
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
function! dapper#view#ThreadsBuffer#_AddThreadEntry(thread, ...) dict abort
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
    call l:self._Log(
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
function! dapper#view#ThreadsBuffer#_UpdateThreads(ids_to_threads) dict abort
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
function! dapper#view#ThreadsBuffer#MakeEntry(thread) dict abort
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
function! dapper#view#ThreadsBuffer#ClimbUp() dict abort
  call s:CheckType(l:self)
endfunction

""
" @dict ThreadsBuffer
" Examine the stack trace of the selected thread.
function! dapper#view#ThreadsBuffer#DigDown() dict abort
  call s:CheckType(l:self)
  let l:long_msg = ''
  try
    let l:tid = l:self._GetSelected()
  catch /ERROR(NotFound)/
    return
  endtry
  call l:self._Log(
      \ 'status',
      \ 'Digging down from ThreadsBuffer to tid:'.l:tid,
      \ l:long_msg
      \ )
  call l:self._DigDownAndPush(l:self._model.thread(l:tid))
endfunction

""
" @dict ThreadsBuffer
" Construct a @dict(StackTraceBuffer) and mark it as this
" @dict(ThreadsBuffer)'s child.
function! dapper#view#ThreadsBuffer#_MakeChild() dict abort
  call s:CheckType(l:self)
  let l:child = dapper#view#StackTraceBuffer#New(l:self._message_passer)
  call l:child.SetParent(l:self)
  return l:child
endfunction

""
" @dict ThreadsBuffer
" Returns the ID of the thread over which theuser's cursor is hovering.
function! dapper#view#ThreadsBuffer#_GetSelected() dict abort
  call s:CheckType(l:self)
  let l:cur_line = line('.')
  if     l:cur_line ==# 1         | normal! j
  elseif l:cur_line ==# line('$') | normal! k
  endif
  let l:tid_line = search(s:thread_id_search_pat, 'bncW')
  if !l:tid_line
    call l:self._Log('error', 'Couldn''t find a selected thread ID',
        \ 'curpos: '.string(getcurpos())."\nbuffer contents:\n".getline(1,'$'))
    throw '(dapper#view#ThreadsBuffer) No thread ID found'
  endif
  let l:tid = matchstr(getline(l:tid_line), '[0-9]*\(\tname\)\@=') + 0
  return l:tid
endfunction
