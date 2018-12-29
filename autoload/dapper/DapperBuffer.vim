" BRIEF:  A Buffer, with additional methods for use in the dapper UI.

" BRIEF:  Construct a DapperBuffer.
function! dapper#DapperBuffer#new(message_passer, ...) abort
  let l:new = call('dapper#Buffer#new', a:000)
  let l:new['TYPE']['DapperBuffer'] = 1
  let l:new['___message_passer___'] = a:message_passer

  let l:new['receive'] =
    \ function('dapper#DapperBuffer#__noImpl', ['receive'])
  let l:new['getRange'] =
    \ function('dapper#DapperBuffer#__noImpl', ['getRange'])
  let l:new['setMappings'] =
    \ function('dapper#DapperBuffer#__noImpl', ['setMappings'])

  let l:new['_request'] =
    \ function('dapper#DapperBuffer#_request')
  let l:new['_subscribe'] =
    \ function('dapper#DapperBuffer#_subscribe')

  return l:new
endfunction

function! dapper#DapperBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'DapperBuffer')
    throw '(dapper#DapperBuffer) Object is not of type DapperBuffer: ' . a:object
  endif
endfunction

function! dapper#DapperBuffer#__noImpl(func_name, ...) abort dict
  call dapper#DapperBuffer#CheckType(l:self)
  throw '(dapper#DapperBuffer) Invoked pure virtual function: '.a:func_name
endfunction

" BRIEF:  Subscribe to the message passer.
" DETAILS:  - Meant to be called from derived class constructors.
"           - Shall have the same interface as `MiddleTalker::subscribe`.
function! dapper#DapperBuffer#_subscribe(pattern, Callback) abort dict
  call dapper#DapperBuffer#CheckType(l:self)
  call l:self['___message_passer___'].subscribe(a:pattern, a:Callback)
endfunction

" BRIEF:  Pass a request to the message passer.
" DETAILS:  - Shall have the same interface as `MiddleTalker::request`.
function! dapper#DapperBuffer#_request(command, request_args, Callback) abort dict
  call dapper#DapperBuffer#CheckType(l:self)
  call l:self['___message_passer___'].request(
      \ a:command, a:request_args, a:Callback)
endfunction

" BRIEF:  Accept an incoming message and update this buffer.
function! dapper#DapperBuffer#receive(msg) abort dict
  throw '(dapper#DapperBuffer#receive) No implementation'
endfunction

" BRIEF:  Get the line range of an 'entry' inside the buffer itself.
" DETAILS:  - Throws `EntryNotFound` if the entry couldn't be found.
" RETURNS:  (v:t_list)  Two-element list containing `v:t_number`s: the first
"                       and last line that make up the 'entry', inclusive.
function! dapper#DapperBuffer#getRange(...) abort dict
  throw '(dapper#DapperBuffer) EntryNotFound'
endfunction

" BRIEF:  Set persistent buffer-local mappings for manipulating this buffer.
function! dapper#DapperBuffer#setMappings() abort dict
  throw '(dapper#DapperBuffer#setMappings) No implementation'
endfunction
