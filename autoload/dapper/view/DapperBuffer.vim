" BRIEF:  A Buffer, with additional methods for use in the dapper UI.

" BRIEF:  Construct a DapperBuffer.
function! dapper#view#DapperBuffer#new(message_passer, ...) abort
  let l:new = call('dapper#view#Buffer#new', a:000)
  let l:new['TYPE']['DapperBuffer'] = 1
  let l:new['___message_passer___'] = a:message_passer

  let l:new['receive'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['receive'])
  let l:new['update'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['update'])
  let l:new['getRange'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['getRange'])
  let l:new['setMappings'] =
    \ function('dapper#view#DapperBuffer#__noImpl', ['setMappings'])

  let l:new['_request'] =
    \ function('dapper#view#DapperBuffer#_request')
  let l:new['_subscribe'] =
    \ function('dapper#view#DapperBuffer#_subscribe')
  let l:new['_log'] =
    \ function('dapper#view#DapperBuffer#_log')

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

" BRIEF:  Subscribe to the message passer.
" DETAILS:  - Meant to be called from derived class constructors.
"           - Shall have the same interface as `MiddleTalker::subscribe`.
function! dapper#view#DapperBuffer#_subscribe(pattern, Callback) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call l:self['___message_passer___'].subscribe(a:pattern, a:Callback)
endfunction

" BRIEF:  Pass a request to the message passer.
" DETAILS:  - Shall have the same interface as `MiddleTalker::request`.
function! dapper#view#DapperBuffer#_request(command, request_args, Callback) abort dict
  call dapper#view#DapperBuffer#CheckType(l:self)
  call l:self['___message_passer___'].request(
      \ a:command, a:request_args, a:Callback)
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

" BRIEF:  Accept an incoming message and update this buffer.
function! dapper#view#DapperBuffer#receive(msg) abort dict
  throw '(dapper#view#DapperBuffer#receive) No implementation'
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
