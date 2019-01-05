" BRIEF:  Object-oriented wrapper around a simple vim buffer.

" BRIEF:  Used for creating unique 'filenames' for newly spawned buffers.
let s:buffer_fname_mangle = 0

" BRIEF:  Make a new Buffer object.
" PARAM:  bufparams   (v:t_dict)    Dictionary populated with buffer
"             properties. Can have the following key-value pairs:
"               - 'bufhidden' (v:t_string)
"               - 'buflisted' (v:t_bool)
"               - 'buftype'   (v:t_string)
"               - 'fname'     (v:t_string)  Name of the newly created buffer.
"                             If empty (''), do not create a new buffer.
"               - 'mangle'    (v:t_bool)  If v:true, append a number to the
"                             given buffer name to make it unique.
"               - 'swapfile'  (v:t_bool)
"
"             All of these are optional and will have default values if not
"             specified. Properties which are also vim settings can have any
"             value that could be assigned to those settings explicitly, e.g.
"             with `let &bufhidden = [...]`.
"
let s:bufsettings = {
    \ 'bufhidden':  'hide',
    \ 'buflisted':  v:false,
    \ 'buftype':    'nofile',
    \ 'swapfile':   v:false,
    \ }
let s:bufparams_default = extend(deepcopy(s:bufsettings), {'mangle': v:true})
let s:bufprops = ['bufhidden', 'buflisted', 'buftype', 'fname', 'swapfile', 'mangle']
function! dapper#view#Buffer#new(...) abort
  let s:buffer_fname_mangle += 1 " guarantee unique buffer name
  let s:bufparams_default['fname'] = 'dapper#view#Buffer::'.s:buffer_fname_mangle
  if (a:0 ==# 0)
    let l:bufparams = s:bufparams_default
  elseif (a:0 ==# 1)
    let l:bufparams = deepcopy(s:bufparams_default)
    let a:bufparams = a:1
    if type(a:bufparams) !=# v:t_dict
      throw '(dapper#view#Buffer) Bad argument type (should be '.v:t_dict
        \.') on arg w/ type '.type(a:bufparams).': '.a:bufparams
    endif
    for l:prop in s:bufprops
      if has_key(a:bufparams, l:prop)
        let l:bufparams[l:prop] = a:bufparams[l:prop]
      endif
    endfor
  else
    throw '(dapper#view#Buffer) Too many arguments to new(): '.string(a:000)
  endif

  if !empty(l:bufparams['fname'])
    " create a buffer with the given name
    " let l:bufnr = bufnr(escape(l:bufparams['fname'], '*?,{}\'), 1)
    let l:bufname = l:bufparams['fname']
    if l:bufparams['mangle'] | let l:bufname .= s:buffer_fname_mangle | endif
    let l:bufnr = bufnr(l:bufname, 1)
    unlet l:bufparams['fname']
  else
    unlet l:bufparams['fname']
    if !empty(keys(l:bufparams))
      throw '(dapper#view#Buffer) Tried setting props without creating a buffer: '
        \.string(l:bufparams)
    endif
  endif

  for [l:prop, l:val] in items(l:bufparams)
    " silently discard unrecognized options
    if !has_key(s:bufsettings, l:prop) | continue | endif
    if type(l:val) ==# v:t_bool | let l:val = l:val + 0 | endif
    call setbufvar(l:bufnr, '&'.l:prop, l:val)
  endfor

  let l:new = {
    \ 'TYPE': {'Buffer': 1},
    \ '__bufnr': l:bufnr,
    \ 'destroy': function('dapper#view#Buffer#destroy'),
    \ 'getbufvar': function('dapper#view#Buffer#getbufvar'),
    \ 'setbufvar': function('dapper#view#Buffer#setbufvar'),
    \ 'bufnr': function('dapper#view#Buffer#bufnr'),
    \ 'open': function('dapper#view#Buffer#open'),
    \ 'switch': function('dapper#view#Buffer#switch'),
    \ 'setBuffer': function('dapper#view#Buffer#setBuffer'),
    \ 'split': function('dapper#view#Buffer#openSplit', [v:false]),
    \ 'vsplit': function('dapper#view#Buffer#openSplit', [v:true]),
    \ 'getLines': function('dapper#view#Buffer#getLines'),
    \ 'replaceLines': function('dapper#view#Buffer#replaceLines'),
    \ 'insertLines': function('dapper#view#Buffer#insertLines'),
    \ 'deleteLines': function('dapper#view#Buffer#deleteLines'),
    \ 'isOpenInTab': function('dapper#view#Buffer#isOpenInTab'),
  \ }

  return l:new
endfunction

function! dapper#view#Buffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Buffer')
  try
    let l:err = '(dapper#view#Buffer) Object is not of type Buffer: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#view#Buffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Perform cleanup for this Buffer object.
function! dapper#view#Buffer#destroy() abort dict
  call dapper#view#Buffer#CheckType(l:self)
  execute 'bwipeout! '.l:self['__bufnr']
endfunction

" BRIEF:  Wrapper around `getbufvar`.
" DETAIL: See `:h getbufvar`.
function! dapper#view#Buffer#getbufvar(varname, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:default = get(a:000, 0, v:false)
  let l:to_return = 0
  execute 'let l:to_return = getbufvar(l:self["__bufnr"], a:varname'
    \ . (type(a:default) !=# v:t_bool ? ', a:default)' : ')')
  return l:to_return
endfunction

" BRIEF:  Wrapper around `setbufvar`.
" DETAIL: See `:h setbufvar`.
function! dapper#view#Buffer#setbufvar(varname, val) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  call setbufvar(l:self['__bufnr'], a:varname, a:val)
endfunction

" RETURN: (v:t_bool)  The buffer number of the buffer owned by this Buffer.
function! dapper#view#Buffer#bufnr() abort dict
  call dapper#view#Buffer#CheckType(l:self)
  return l:self['__bufnr']
endfunction

" BRIEF:  Open this buffer in the focused window.
" PARAM:  cmd   (v:t_string?)   See `:h cmd`. (Should *include* leading `+`.)
function! dapper#view#Buffer#open(...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  if !a:0 | execute 'buffer '.        l:self['__bufnr']
  else    | execute 'buffer '.a:1.' '.l:self['__bufnr']
  endif
endfunction

" BRIEF:  Move the cursor to (one of) this buffer's window(s) in the given tab.
" DETAILS:  Throws an `ERROR(NotFound)` if this buffer isn't open in the tab(s)
"     specified. Prefers to switch to a buffer in the current tabpage, if
"     possible. Does nothing if the current tabpage is 'acceptable' and the
"     current window has this buffer open.
" PARAM:  open_in_any (v:t_bool?) `v:true` when it's okay to switch to an
"     instance of this buffer in a different tabpage.
" PARAM:  tabnr     (v:t_number?) The tab page in which to search.
function! dapper#view#Buffer#switch(...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:open_in_any = get(a:000, 0, v:true)
  let a:tabnr = get(a:000, 1, tabpagenr())
  let l:bufnr = l:self.bufnr()
  if a:tabnr ==# tabpagenr() || a:open_in_any
    " check if already open and active
    if winnr() ==# bufwinnr(l:bufnr) | return | endif
  endif
  let l:range = [a:tabnr]
  if a:open_in_any
    call extend(l:range,
        \ range(1, a:tabnr - 1) + range(a:tabnr + 1, tabpagenr('$')))
  endif
  for l:tab in l:range
    if !l:self.isOpenInTab(l:tab) | continue | endif
    execute 'tabnext '.l:tab
    let l:winnr = bufwinnr(l:bufnr)
    execute l:winnr.'wincmd w'
    break
  endfor
  if bufnr('%') !=# l:bufnr || (!a:open_in_any && tabpagenr() !=# a:tabnr)
    throw 'ERROR(NotFound) (dapper#view#Buffer) Didn''t switch to buffer!'
  endif
endfunction

" BRIEF:  Replace the buffer owned by this Buffer object.
" PARAM:  bufnr   (v:t_number)  The `bufnr()` of the buffer to be owned.
" PARAM:  action  (v:t_string)  Whether to do nothing (''), unload ('bunload'),
"                               delete ('bdelete'), or wipeout ('bwipeout')
"                               the buffer being replaced.
" PARAM:  force   (v:t_bool)    Whether to ignore unsaved changes in a buffer
"                               being unloaded, deleted, or wiped out.
" RETURNS:  (v:t_number)  The `bufnr` of the buffer being replaced.
function! dapper#view#Buffer#setBuffer(bufnr, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  if !bufexists(a:bufnr)
    throw '(dapper#view#Buffer) Cannot find buffer: '.a:bufnr
  endif
  let a:action = get(a:000, 0, '')
  let a:force  = get(a:000, 1, v:true)
  let l:to_return = l:self['__bufnr']
  if      a:action ==# ''
  elseif  a:action ==# 'bunload'
     \ || a:action ==# 'bdelete'
     \ || a:action ==# 'bwipeout'
    execute a:action . a:force ? '! ' : ' ' . l:to_return
  else
    throw '(dapper#view#Buffer) Bad argument value: '.a:action
  endif
  let l:self['__bufnr'] = a:bufnr
  return l:to_return
endfunction

" BRIEF:  Open this buffer in a split.
" PARAM:  cmd   (v:t_string?)   See `:h cmd`. Should include leading `+`. Can
"                               be empty string.
" PARAM:  pos   (v:t_string?)   See `:h topleft` and `:h botright`. Can be
"                               empty string.
" PARAM:  size  (v:t_number?)   The height (if making a split) or the width
"                               (if making a vsplit). If zero, will be
"                               ignored.
function! dapper#view#Buffer#openSplit(open_vertical, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:ornt = a:open_vertical ? 'vertical ' : ' '
  let a:cmd  = get(a:000, 0, '')
  let a:pos  = get(a:000, 1, '')
  let a:size = get(a:000, 2, 0)

  execute 'silent '.a:pos.' '.a:ornt.' '.a:size.' split'
  execute 'buffer! '.l:self['__bufnr']
endfunction

" RETURN: (v:t_list)  A list containing the requested lines from this buffer.
" PARAM:  after (v:t_number)  Include lines starting *after* this line number.
" PARAM:  rnum  (v:t_number?) The last line to include in the range. If not
"                             specified, will be equal to lnum+1 (i.e. not
"                             specifying rnum will return a one-item list with
"                             the given line).
" PARAM:  strict_indexing   (v:t_bool?)   Throw error on 'line out-of-range.'
function! dapper#view#Buffer#getLines(lnum, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:strict_indexing = get(a:000, 1, v:false)
  let a:rnum = get(a:000, 0, a:lnum)
  return nvim_buf_get_lines(l:self['__bufnr'], a:lnum, a:rnum, a:strict_indexing)
endfunction

" BRIEF:  Set, add to, or remove lines. Wraps `nvim_buf_set_lines`.
" PARAM:  after     (v:t_number)  Replace lines starting after this line number.
" PARAM:  through   (v:t_number)  Replace until this line number, inclusive.
" PARAM:  strict_indexing   (v:t_bool?)   Throw error on 'line out-of-range.'
" DETAILS:  See `:h nvim_buf_set_lines` for details on function parameters.
"           `{strict_indexing}` is always `v:false`.
function! dapper#view#Buffer#replaceLines(after, through, replacement, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:strict_indexing = get(a:000, 0, v:false)
  call nvim_buf_set_lines(
    \ l:self['__bufnr'],
    \ a:after,
    \ a:through,
    \ a:strict_indexing,
    \ a:replacement)
endfunction

" BRIEF:  Insert lines at a position.
" PARAM:  after   (v:t_number)  Insert text right after this line number.
" PARAM:  lines   (v:t_list)    List of `v:t_string`s: the text to insert.
" PARAM:  strict_indexing   (v:t_bool?)   Throw error on 'line out-of-range.'
function! dapper#view#Buffer#insertLines(after, lines, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:strict_indexing = get(a:000, 0, v:false)
  call nvim_buf_set_lines(
    \ l:self['__bufnr'],
    \ a:after,
    \ a:after,
    \ a:strict_indexing,
    \ a:lines)
endfunction

" BRIEF:  Remove lines over a range.
" PARAM:  after     (v:t_number)  Remove lines starting after this line number.
" PARAM:  through   (v:t_number)  Remove until this line number, inclusive.
" PARAM:  strict_indexing   (v:t_bool?)   Throw error on 'line out-of-range.'
function! dapper#view#Buffer#deleteLines(after, through, ...) abort dict
  call dapper#view#Buffer#CheckType(l:self)
  let a:strict_indexing = get(a:000, 0, v:false)
  call nvim_buf_set_lines(
    \ l:self['__bufnr'],
    \ a:after,
    \ a:through,
    \ a:strict_indexing,
    \ [])
endfunction

" RETURNS:  (v:t_bool)  Whether this Buffer is open in the given tab.
" PARAM:  tabnr   (v:t_number?) The tabpage in which to search. Defaults to
"     the current tabpage.
function! dapper#view#Buffer#isOpenInTab(...) abort dict
  let a:tabnr = get(a:000, 0, tabpagenr())
  let l:this_buf = l:self.bufnr()
  let l:bufs_in_tab = tabpagebuflist(a:tabnr)
  for l:buf in l:bufs_in_tab
    if l:buf ==# l:this_buf | return v:true | endif
  endfor
  return v:false
endfunction
