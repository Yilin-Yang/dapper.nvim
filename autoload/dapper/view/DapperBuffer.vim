""
" @private
" @dict DapperBuffer
" A Buffer, with additional methods for use in the dapper UI.
"
" In addition to encapsulating a buffer, a `DapperBuffer` also:
"
" - Acts as a parent or child to other `DapperBuffer`s, allowing
"   `DapperBuffer`s to organize as a tree: UI updates and information about
"   for 'digging down' from one level of information to another (e.g. from a
"   list of all running threads to a stack trace for a particular thread), and
"   for 'climbing up' from that deeper level back to the parent level.

let s:typename = 'DapperBuffer'

""
" @dict DapperBuffer
" @function dapper#view#DapperBuffer#New()
" Construct a DapperBuffer.
"
" {message_passer} is the message-passing interface that DapperBuffer will
" use, which shall have the same interface as @dict(MiddleTalker).
"
" For {bufparams}, see @function(typevim#Buffer#New).
function! dapper#view#DapperBuffer#new(message_passer, ...) abort
  let l:bufparams = get(a:000, 0, {})
  let l:base = typevim#Buffer#New(l:bufparams)

  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_parent': 0,
      \ '_children': [],
      \ 'Show': typevim#make#AbstractFunc(s:typename, 'Show', []),
      \ 'GetRange': typevim#make#AbstractFunc(s:typename, 'GetRange', []),
      \ 'SetMappings': typevim#make#AbstractFunc(s:typename, 'SetMappings', []),
      \ 'ConfigureBuffer': typevim#make#Member('ConfigureBuffer'),
      \ 'ClimbUp': typevim#make#member('ClimbUp'),
      \ 'DigDown': typevim#make#AbstractFunc(s:typename, 'DigDown', []),
      \ '_DigDownAndPush': typevim#make#Member('_DigDownAndPush'),
      \ 'SetParent': typevim#make#Member('SetParent'),
      \ 'GetParent': typevim#make#Member('GetParent'),
      \ 'AddChild': typevim#make#Member('AddChild'),
      \ 'GetChildren': typevim#make#Member('GetChildren'),
      \ '_MakeChild': typevim#make#AbstractFunc(s:typename, '_MakeChild', []),
      \ '_Log': typevim#make#Member('_Log'),
      \ '_GetOpenInTab': typevim#make#Member('_GetOpenInTab'),
      \ }
  call typevim#make#Derived(s:typename, l:base, l:new)

  " set 'self' as a buffer-local variable
  call setbufvar(l:new.bufnr(), 'dapper_buffer', l:new)

  " monkey-patch the `open` method; invoke `setMappings` after opening
  let l:new['Buffer#Open'] = l:new.Open
  let l:new.Open = typevim#make#Member('Open')

  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict DapperBuffer
" Log a report.
function! dapper#view#DapperBuffer#_Log(kind, brief, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:kind)
  call maktaba#ensure#IsString(a:brief)
  call call(l:self['_message_passer'].NotifyReport, [a:kind, a:brief] + a:000)
endfunction

""
" @dict DapperBuffer
" Get the line range of an "entry" inside the buffer itself as a two-element
" list of numbers, which are the first and last line that make up the 'entry',
" inclusive.
"
" @throws NotFound if the given "entry" could not be found.
function! dapper#view#DapperBuffer#getRange(...) dict abort
  throw maktaba#error#NotFound('Could not find entry: %s',
      \ typevim#object#ShallowPrint(a:000))
endfunction

""
" @dict DapperBuffer
" Set buffer-local settings for a DapperBuffer.
function! dapper#view#DapperBuffer#ConfigureBuffer() dict abort
  call s:CheckType(l:self)
  setlocal nolist
  setlocal tabstop=8
  setlocal conceallevel=0
  set syntax=dapper
endfunction

""
" @dict DapperBuffer
" Step up one level to this buffer's parent. If [fail_silently] is false, this
" will throw an ERROR(NotFound) if no parent has been set.
"
" Calls to `climbUp` will move the cursor to the parent buffer,
" either by switching the focused window or by opening the parent buffer
" in the current window (if it wasn't already open in the same tabpage.)
"
" @default fail_silently=0
function! dapper#view#DapperBuffer#ClimbUp(...) dict abort
  call s:CheckType(l:self)
  let a:fail_silently = get(a:000, 0, 0)
  let l:parent = l:self._parent
  if type(l:parent) ==# v:t_number
    if a:fail_silently | return | endif
    throw maktaba#error#NotFound(
        \ 'No parent set for this DapperBuffer: %s',
        \ typevim#object#ShallowPrint(l:self))
  endif
  try
    call l:parent.Switch()
  catch /ERROR(NotFound)/
    call l:parent.Open()
  endtry
endfunction

""
" @dict DapperBuffer
" Push the given item {to_show} to all children, and switch to one. Meant to
" be called after determining what {to_show} during a call to
" @function(dapper#view#DapperBuffer#DigDown).
function! dapper#view#DapperBuffer#_DigDownAndPush(to_show) dict abort
  call s:CheckType(l:self)
  let l:children = l:self._children
  if empty(l:children)
    call add(l:children, l:self._MakeChild())
  endif
  let l:open_in_same = 0
  for l:child in l:children
    call l:child.Show(a:to_show)
    if !empty(l:open_in_same) | continue | endif
    if l:child.IsOpenInTab() | let l:open_in_same = l:child | endif
  endfor
  if empty(l:open_in_same)
    try
      call l:children[0].Switch()
    catch /ERROR(NotFound)/
      " not open in any tabs
      call l:children[0].Open()
    endtry
  else
    call l:open_in_same.Switch()
  endif
endfunction

""
" @dict DapperBuffer
" Open this buffer, and trigger setup/buffer-local mappings.
function! dapper#view#DapperBuffer#Open() dict abort
  call s:CheckType(l:self)
  call l:self['Buffer#Open']()
  call l:self.SetMappings()
  call l:self.ConfigureBuffer()
endfunction

""
" @dict DapperBuffer
" Set the parent DapperBuffer of this DapperBuffer.
function! dapper#view#DapperBuffer#SetParent(new_parent) dict abort
  call s:CheckType(l:self)
  call dapper#view#DapperBuffer#CheckType(a:new_parent)
  let l:self._parent = a:new_parent
endfunction

""
" @dict DapperBuffer
" Get the parent DapperBuffer of this DapperBuffer.
function! dapper#view#DapperBuffer#GetParent() dict abort
  call s:CheckType(l:self)
  return l:self._parent
endfunction

""
" @dict DapperBuffer
" Mark a DapperBuffer as this buffer's child.
function! dapper#view#DapperBuffer#AddChild(new_child) dict abort
  call s:CheckType(l:self)
  call s:CheckType(a:new_child)
  let l:self._children += [a:new_child]
endfunction

""
" @dict DapperBuffer
" Returns a list of all of this buffer's children, in no particular order.
function! dapper#view#DapperBuffer#GetChildren() dict abort
  call s:CheckType(l:self)
  return l:self._children
endfunction

""
" @dict DapperBuffer
" Returns the the first DapperBuffer in the given list of {buffers} that is
" open in the tabpage having [tabnr], or the number 0, if none could be found.
"
" @default tabnr=the current tab
" @throws WrongType if {buffers} is not a list of @dict(DapperBuffer) objects or if [tabnr] is not a number.
function! dapper#view#DapperBuffer#_GetOpenInTab(buffers, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:buffers)
  let l:tabnr = get(a:000, 0, tabpagenr())
  for l:buf in a:buffers
    call s:CheckType(l:buf)
    if l:buf.IsOpenInTab(l:tabnr) | return l:buf | endif
  endfor
  return 0
endfunction
