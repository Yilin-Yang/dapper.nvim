" BRIEF:  A Buffer, with additional methods for use in the dapper UI.

" BRIEF:  Construct a DapperBuffer.
" PARAM:  bufparams       (v:t_dict?)   See `dapper#view#Buffer#new`.
" PARAM:  debug_logger    (dapper#log#DebugLogger?)
function! dapper#view#DapperBuffer#new(...) abort
  let a:debug_logger = get(a:000, 0, dapper#log#DebugLogger#dummy())
  let l:new = call('dapper#view#Buffer#new', a:000[1:])
  let l:new['TYPE']['DapperBuffer'] = 1
  let l:new['_debug_logger'] = a:debug_logger
  let l:new['_subs'] = []

  let l:new['show'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['show'])
  let l:new['getRange'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['getRange'])
  let l:new['setMappings'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['setMappings'])

  let l:new['emit'] = function('dapper#view#DapperBuffer#emit')
  let l:new['subscribe'] = function('dapper#view#DapperBuffer#subscribe')
  let l:new['unsubscribe'] = function('dapper#view#DapperBuffer#unsubscribe')

  let l:new['_log'] = function('dapper#view#DapperBuffer#_log')

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
    echo a:object
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
      call l:self['_debug_logger'].notifyReport(
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
  let l:msg = call('dapper#dap#Report#new', [0, '', a:kind, a:brief] + a:000)
  call l:self['___message_passer___'].receive(l:msg)
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

" BRIEF:  Open this buffer, and trigger setup/buffer-local mappings.
function! dapper#view#DapperBuffer#open() abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call l:self['Buffer#open']()
  call l:self.setMappings()
endfunction
