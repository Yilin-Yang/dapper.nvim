" BRIEF:  Object-oriented wrapper around a simple vim buffer.

" BRIEF:  Used for creating unique 'filenames' for newly spawned buffers.
let s:buffer_fname_mangle = localtime()

" BRIEF:  Make a new Buffer object.
" PARAM:  bufparams   (v:t_dict)    Dictionary populated with buffer
"             properties. Can have the following key-value pairs:
"               - 'bufhidden' (v:t_string)
"               - 'buflisted' (v:t_bool)
"               - 'buftype'   (v:t_string)
"               - 'fname'     (v:t_string)  Name of the newly created buffer.
"               - 'swapfile'  (v:t_bool)
"
"             All of these are optional and will have default values if not
"             specified. Properties which are also vim settings can have any
"             value that could be assigned to those settings explicitly, e.g.
"             with `let &bufhidden = [...]`.
"
let s:bufparams_default = {
  \ 'bufhidden':  'hide',
  \ 'buflisted':  v:false,
  \ 'buftype':    'nofile',
  \ 'swapfile':   v:false,
\ }
let s:bufprops = ['bufhidden', 'buflisted', 'buftype', 'fname', 'swapfile']
function! dapper#Buffer#new(...) abort
  let s:buffer_fname_mangle += 1 " guarantee unique buffer name
  let s:bufparams_default['fname'] = 'dapper#Buffer::'.s:buffer_fname_mangle
  if (a:0 ==# 0)
    let l:bufparams = s:bufparams_default
  elseif (a:0 ==# 1)
    let l:bufparams = deepcopy(s:bufparams_default)
    let a:bufparams = a:1
    if type(a:bufparams) !=# v:t_dict
      throw '(dapper#Buffer) Bad argument type (should be '.v:t_dict
        \.') on arg w/ type '.type(a:bufparams).': '.a:bufparams
    endif
    for l:prop in s:bufprops
      if has_key(a:bufparams, l:prop)
        let l:bufparams[l:prop] = a:bufparams[l:prop]
      endif
    endfor
  else
    throw '(dapper#Buffer) Too many arguments to new(): '.string(a:000)
  endif

  " create a buffer with the given name
  let l:bufnr = bufnr(escape(l:bufparams['fname'], '~*.,$?{}\[]'), 1)
  unlet l:bufparams['fname']

  for [l:prop, l:val] in items(l:bufparams)
    if type(l:val) ==# v:t_bool | let l:val = l:val + 0 | endif
    call setbufvar(l:bufnr, '&'.l:prop, l:val)
  endfor

  let l:new = {
    \ 'TYPE': {'Buffer': 1},
    \ '__bufnr': l:bufnr,
    \ 'getbufvar': function('dapper#Buffer#getbufvar'),
    \ 'setbufvar': function('dapper#Buffer#setbufvar'),
    \ 'bufnr': function('dapper#Buffer#bufnr'),
    \ 'open': function('dapper#Buffer#open'),
    \ 'split': function('dapper#Buffer#openSplit', [v:false]),
    \ 'vsplit': function('dapper#Buffer#openSplit', [v:true]),
  \ }

  return l:new
endfunction

function! dapper#Buffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'Buffer')
    throw '(dapper#Buffer) Object is not of type Buffer: ' . a:object
  endif
endfunction

" BRIEF:  Wrapper around `getbufvar`.
" DETAIL: See `:h getbufvar`.
function! dapper#Buffer#getbufvar(varname, ...) abort dict
  call dapper#Buffer#CheckType(l:self)
  let a:default = get(a:000, 0, v:false)
  let l:to_return = 0
  execute 'let l:to_return = getbufvar(l:self["__bufnr"], a:varname'
    \ . (type(a:default) !=# v:t_bool ? ', a:default)' : ')')
  return l:to_return
endfunction

" BRIEF:  Wrapper around `setbufvar`.
" DETAIL: See `:h setbufvar`.
function! dapper#Buffer#setbufvar(varname, val) abort dict
  call dapper#Buffer#CheckType(l:self)
  call setbufvar(l:self['__bufnr'], a:varname, a:val)
endfunction

" RETURN: (v:t_bool)  The buffer number of the buffer owned by this Buffer.
function! dapper#Buffer#bufnr() abort dict
  call dapper#Buffer#CheckType(l:self)
  return l:self['__bufnr']
endfunction

" BRIEF:  Open this buffer in the focused window.
" PARAM:  cmd   (v:t_string?)   See `:h cmd`. (Should *include* leading `+`.)
function! dapper#Buffer#open(...) abort dict
  call dapper#Buffer#CheckType(l:self)
  if !a:0 | execute 'buffer '.        l:self['__bufnr']
  else    | execute 'buffer '.a:1.' '.l:self['__bufnr']
  endif
endfunction

" BRIEF:  Open this buffer in a split.
" PARAM:  cmd   (v:t_string?)   See `:h cmd`. Should include leading `+`. Can
"                               be empty string.
" PARAM:  pos   (v:t_string?)   See `:h topleft` and `:h botright`. Can be
"                               empty string.
" PARAM:  size  (v:t_number?)   The height (if making a split) or the width
"                               (if making a vsplit). If zero, will be
"                               ignored.
function! dapper#Buffer#openSplit(open_vertical, ...) abort dict
  call dapper#Buffer#CheckType(l:self)
  let a:ornt = a:open_vertical ? 'vertical ' : ' '
  let a:cmd  = get(a:000, 0, '')
  let a:pos  = get(a:000, 1, '')
  let a:size = get(a:000, 2, 0)

  execute 'silent '.a:pos.' '.a:ornt.' '.a:size.' split'
  execute 'buffer! '.l:self['__bufnr']
endfunction
