" BRIEF:  Stores information about different Threads.
" DETAILS:  Stores Thread information in the following format:
"           (dapper#Thread) struct:
"             - id      (v:t_number)
"             - name    (v:t_string)
"             - status  (v:t_string)
"
"           Functionally equivalent to `DebugProtocol.Thread`.

function! dapper#ThreadsCache#new() abort
  let l:new = {
    \ '_ids_to_threads': {},
    \ 'TYPE': {'ThreadsCache': 1},
    \ 'get': function('dapper#ThreadsCache#get'),
    \ 'update': function('dapper#ThreadsCache#update'),
  \ }
  return l:new
endfunction

function! dapper#ThreadsCache#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ThreadsCache')
  try
    let l:err = '(dapper#ThreadsCache) Object is not of type ThreadsCache: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#ThreadsCache) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Get the Thread with the given ID, initializing it if it doesn't exist.
function! dapper#ThreadsCache#get(thread_id) abort dict
  call dapper#ThreadsCache#CheckType(l:self)
  let l:itt = l:self['_ids_to_threads']
  if !has_key(l:itt, a:thread_id)
    let l:itt[a:thread_id] = {
      \ 'id': a:thread_id,
      \ 'name': 'unnamed',
      \ 'status': '(N/A)'
    \ }
  endif
  return l:itt[a:thread_id]
endfunction

" BRIEF:  Update the properties of a particular thread.
function! dapper#ThreadsCache#update(thread_id, new_props) abort dict
  call dapper#ThreadsCache#CheckType(l:self)
  let l:thread = l:self.get(a:thread_id)
  for [l:prop, l:value] in items(a:new_props)
    let l:thread[l:prop] = l:value
  endfor
  return l:thread
endfunction
