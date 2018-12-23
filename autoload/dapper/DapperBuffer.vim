" BRIEF:  A Buffer, with additional methods for use in the dapper UI.

" BRIEF:  Construct a DapperBuffer.
function! dapper#DapperBuffer#new(...) abort
  let l:new = call('dapper#Buffer#new', a:000)
  let l:new['TYPE']['DapperBuffer'] = 1

  let l:new['receive'] =
    \ function('dapper#DapperBuffer#__noImpl', ['receive'])
  let l:new['getRange'] =
    \ function('dapper#DapperBuffer#__noImpl', ['getRange'])
  let l:new['setMappings'] =
    \ function('dapper#DapperBuffer#__noImpl', ['setMappings'])
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
