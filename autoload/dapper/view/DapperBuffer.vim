" BRIEF:  A Buffer, with additional methods for use in the dapper UI.
" DETAILS:  In addition to encapsulating a buffer, a `DapperBuffer` also:
"
"   - Acts as a parent or child to other `DapperBuffer`s, allowing
"   `DapperBuffer`s to organize as a tree: UI updates and information about
"   the debugger state can be propagated through the tree.
"
"   - Acts as a 'level' within said tree: `DapperBuffer` provides an interface
"   for 'digging down' from one level of information to another (e.g. from a
"   list of all running threads to a stack trace for a particular thread), and
"   for 'climbing up' from that deeper level back to the parent level.

" BRIEF:  Construct a DapperBuffer.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  bufparams       (v:t_dict?)   See `dapper#view#Buffer#new`.
function! dapper#view#DapperBuffer#new(message_passer, ...) abort
  let a:bufparams = get(a:000, 0, {})
  let l:new = dapper#view#Buffer#new(a:bufparams)
  let l:new['TYPE']['DapperBuffer'] = 1
  let l:new['_message_passer'] = a:message_passer
  let l:new['_subs'] = []
  let l:new['_parent'] = 0
  let l:new['_children'] = []

  let l:new['show'] =
      \ function('dapper#view#DapperBuffer#__noImpl', ['show'])
  let l:new['getRange'] =
      \ function('dapper#view#DapperBuffer#__noImpl', ['getRange'])
  let l:new['setMappings'] =
      \ function('dapper#view#DapperBuffer#__noImpl', ['setMappings'])
  let l:new['configureBuffer'] =
      \ function('dapper#view#DapperBuffer#configureBuffer')

  let l:new['climbUp'] =
      \ function('dapper#view#DapperBuffer#climbUp')
  let l:new['digDown'] =
      \ function('dapper#view#DapperBuffer#__noImpl', ['digDown'])
  let l:new['_digDownAndPush'] =
      \ function('dapper#view#DapperBuffer#_digDownAndPush')

  let l:new['setParent'] =
      \ function('dapper#view#DapperBuffer#setParent')
  let l:new['getParent'] =
      \ function('dapper#view#DapperBuffer#getParent')
  let l:new['addChild'] =
      \ function('dapper#view#DapperBuffer#addChild')
  let l:new['getChildren'] =
      \ function('dapper#view#DapperBuffer#getChildren')
  let l:new['_makeChild'] =
      \ function('dapper#view#DapperBuffer#__noImpl', ['_makeChild'])

  let l:new['_log'] =
      \ function('dapper#view#DapperBuffer#_log')
  let l:new['_getOpenInTab']
      \ = function('dapper#view#DapperBuffer#_getOpenInTab')

  " set 'self' as a buffer-local variable
  call setbufvar(l:new.bufnr(), 'dapper_buffer', l:new)

  " monkey-patch the `open` method; invoke `setMappings` after opening
  let l:new['Buffer#open'] = l:new['open']
  let l:new['open'] =
    \ function('dapper#view#DapperBuffer#open')

  return l:new
endfunction

function! dapper#view#DapperBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DapperBuffer')
  try
    let l:err = '(dapper#view#DapperBuffer) Object is not of type DapperBuffer: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#view#DapperBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#view#DapperBuffer#__noImpl(func_name, ...) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  throw '(dapper#view#DapperBuffer) Invoked pure virtual function: '.a:func_name
endfunction

" BRIEF:  Push the given object to all subscribers.
" DETAILS:  If a callback fails (i.e. throws), that subscriber will be
"     automatically unsubscribed.
function! dapper#view#DapperBuffer#emit(obj) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  let l:callbacks = l:self['_subs']
  let l:i = 0 | while l:i <# len(l:callbacks)
    try
      call l:Cb(a:obj)
      let l:i += 1
    catch
      " assume destroyed, unsubscribe this object
      call l:self['_message_passer'].notifyReport(
          \ 'status',
          \ '(view#DapperBuffer) Push failed, unsubbing:'
            \ . dapper#helpers#StrDump(l:Cb),
          \ 'Callback object was: '.dapper#helpers#StrDump(a:obj)
          \ )
      unlet l:callbacks[l:i]
    endtry
  endwhile
endfunction

" BRIEF:  Subscribe to pushes from this DapperBuffer.
function! dapper#view#DapperBuffer#subscribe(Callback) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  if type(a:Callback) !=# v:t_func
    throw '(dapper#view#DapperBuffer) Not a funcref:'
        \ . dapper#helpers#StrDump(a:Callback)
  endif
  let l:self['_subs'] += [a:Callback]
endfunction

" BRIEF:  Unsubscribe from pushes from this DapperBuffer.
" RETURNS:  (v:t_bool)  `v:true` if a subscription was removed, `v:false`
"     otherwise.
function! dapper#view#DapperBuffer#unsubscribe(Callback) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  if type(a:Callback) !=# v:t_func
    throw '(dapper#view#DapperBuffer) Not a funcref:'
        \ . dapper#helpers#StrDump(a:Callback)
  endif
  let l:callbacks = l:self['_subs']
  let l:i = 0 | while l:i <# len(l:callbacks)
    if l:callbacks[l:i] ==# a:Callback
      unlet l:callbacks[l:i]
      return v:true
    endif
  let l:i += 1 | endwhile
  return v:false
endfunction

" BRIEF:  Log a report.
" PARAM:  kind  (v:t_string)
" PARAM:  brief (v:t_string)
" PARAM:  long  (v:t_string?)
" PARAM:  alert (v:t_bool?)
" PARAM:  other (any?)
function! dapper#view#DapperBuffer#_log(kind, brief, ...) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call call(l:self['_message_passer'].notifyReport, [a:kind, a:brief] + a:000)
endfunction

" BRIEF:  Make this buffer display the given object.
" PARAM:  obj   (any)   Object to display. Derived types will place greater
"     restrictions on the type of this object.
function! dapper#view#DapperBuffer#show(...) abort dict
  throw '(dapper#view#DapperBuffer#show) No implementation'
endfunction

" BRIEF:  Get the line range of an 'entry' inside the buffer itself.
" DETAILS:  - Throws `EntryNotFound` if the entry couldn't be found.
" RETURNS:  (v:t_list)  Two-element list containing `v:t_number`s: the first
"                       and last line that make up the 'entry', inclusive.
function! dapper#view#DapperBuffer#getRange(...) abort dict
  throw '(dapper#view#DapperBuffer) EntryNotFound'
endfunction

" BRIEF:  Set persistent buffer-local mappings for manipulating this buffer.
function! dapper#view#DapperBuffer#setMappings() abort dict
  throw '(dapper#view#DapperBuffer#setMappings) No implementation'
endfunction

" BRIEF:  Set buffer-local settings for a DapperBuffer.
function! dapper#view#DapperBuffer#configureBuffer() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  setlocal nolist
  setlocal tabstop=8
  setlocal conceallevel=0
  set syntax=dapper
endfunction

" BRIEF:  'Step up' to this buffer's parent.
" PARAM:  fail_silently (v:t_bool?) Whether to throw an exception if no parent
"     has been set.
function! dapper#view#DapperBuffer#climbUp(...) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  let a:fail_silently = get(a:000, 0, v:false)
  let l:parent = l:self['_parent']
  if type(l:parent) ==# v:t_number
    if a:fail_silently | return | endif
    throw '(dapper#view#DapperBuffer) No parent set for this DapperBuffer'
  endif
  try
    call l:parent.switch()
  catch /ERROR(NotFound)/
    call l:parent.open()
  endtry
endfunction

" BRIEF:  'Dig down' to a detailed view of the selected item.
function! dapper#view#DapperBuffer#digDown() abort dict
  throw '(dapper#view#DapperBuffer#digDown) No implementation'
endfunction

" BRIEF:  Push the given item `to_show` to all children, and switch to one.
" DETAILS:  Meant to be called after determining what `to_show` during a call
"     to `digDown`.
function! dapper#view#DapperBuffer#_digDownAndPush(to_show) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  let l:children = l:self['_children']
  if empty(l:children)
    call add(l:children, l:self._makeChild())
  endif
  let l:open_in_same = 0
  for l:child in l:children
    call l:child.show(a:to_show)
    if !empty(l:open_in_same) | continue | endif
    if l:child.isOpenInTab() | let l:open_in_same = l:child | endif
  endfor
  if empty(l:open_in_same)
    try
      call l:children[0].switch()
    catch /ERROR(NotFound)/
      " not open in any tabs
      call l:children[0].open()
    endtry
  else
    call l:open_in_same.switch()
  endif
endfunction

" BRIEF:  Open this buffer, and trigger setup/buffer-local mappings.
function! dapper#view#DapperBuffer#open() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call l:self['Buffer#open']()
  call l:self.setMappings()
  call l:self.configureBuffer()
endfunction

" BRIEF:  Set the parent DapperBuffer of this DapperBuffer.
" DETAILS:  Calls to `climbUp` will move the cursor to the parent buffer,
"     either by switching the focused window or by opening the parent buffer
"     in the current window (if it wasn't already open in the same tabpage.)
function! dapper#view#DapperBuffer#setParent(new_parent) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call dapper#view#DapperBuffer#CheckType(a:new_parent)
  let l:self['_parent'] = a:new_parent
endfunction

" BRIEF:  Get the parent DapperBuffer of this DapperBuffer.
function! dapper#view#DapperBuffer#getParent() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  return l:self['_parent']
endfunction

" BRIEF:  Mark a DapperBuffer as this buffer's child.
" DETAILS:  Calls to `addChild` will move the cursor to one of the buffer's
"     children, either by switching the focused window or by opening that
"     child buffer in the current window (if none are already open in the same
"     tabpage.)
function! dapper#view#DapperBuffer#addChild(new_child) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call dapper#view#DapperBuffer#CheckType(new_child)
  let l:self['_children'] += [a:new_child]
endfunction

" RETURNS:  A list of all of this buffer's children, in no particular order.
function! dapper#view#DapperBuffer#getChildren() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  return l:self['_children']
endfunction

" RETURNS:  (dapper#view#DapperBuffer)  A newly constructed child DapperBuffer.
function! dapper#view#DapperBuffer#_makeChild() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  throw '(dapper#view#DapperBuffer#_makeChild) No implementation'
endfunction

" RETURNS:  (dapper#view#DapperBuffer)  The first DapperBuffer in the given
"     list that is open in the given tabpage, or the number 0, if none could
"     be found.
" PARAM:  buffers (v:t_list)    A list of DapperBuffers.
" PARAM:  tabnr   (v:t_number?) The tabpage in which to search. Defaults to
"     the current tabpage.
function! dapper#view#DapperBuffer#_getOpenInTab(buffers, ...) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  let a:tabnr = get(a:000, 0, tabpagenr())
  if type(a:buffers) !=# v:t_list
    throw 'ERROR(WrongType) (dapper#view#DapperBuffer) Bad argument: '
        \ . a:buffers
  endif
  for l:buf in a:buffers
    call dapper#view#DapperBuffer#CheckType(l:buf)
    if l:buf.isOpenInTab(a:tabnr) | return l:buf | endif
  endfor
  return 0
endfunction
