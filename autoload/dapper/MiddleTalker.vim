" BRIEF:  The interface between the VimL frontend and the TypeScript 'middle-end'.

" BRIEF:  Get the MiddleTalker singleton, or make one if it doesn't yet exist.
function! dapper#MiddleTalker#get() abort
  if exists('g:dapper_middletalker')
    try
      call dapper#MiddleTalker#CheckType(g:dapper_middletalker)
      " already exists
      return g:dapper_middletalker
    catch " invalid object, okay to overwrite
    endtry
  endif

  let g:dapper_middletalker = {
    \ 'TYPE': {'MiddleTalker': 1},
    \ '__next_id': 0,
    \ '__patterns_to_callbacks': {},
    \ '__ids_to_callbacks': {},
    \ '__getID': function('dapper#MiddleTalker#__getID'),
    \ 'receive': function('dapper#MiddleTalker#receive'),
    \ 'request': function('dapper#MiddleTalker#request'),
    \ 'subscribe': function('dapper#MiddleTalker#subscribe'),
    \ 'unsubscribe': function('dapper#MiddleTalker#unsubscribe'),
    \ 'notifyReport': function('dapper#MiddleTalker#notifyReport')
  \ }

  return g:dapper_middletalker
endfunction

function! dapper#MiddleTalker#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'MiddleTalker')
  try
    let l:err = '(dapper#MiddleTalker) Object is not of type MiddleTalker: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#MiddleTalker) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURN: (v:t_number)  A request ID, guaranteed to be distinct from those
"                       of all existing requests.
function! dapper#MiddleTalker#__getID() abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  let l:self['__next_id'] += 1
  return l:self['__next_id']
endfunction

" BRIEF:  Receive a response or event, passing it to subscribers.
function! dapper#MiddleTalker#receive(msg) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  let l:id = a:msg['vim_id']
  if l:id ># 0 " msg is a response to a request
    call  l:self['__ids_to_callbacks'][l:id](a:msg)
    unlet l:self['__ids_to_callbacks'][l:id]
  endif
  let l:pats_to_cbs = l:self['__patterns_to_callbacks']
  let l:typename = a:msg['vim_msg_typename']
  for [l:pat, l:Cbs] in items(l:pats_to_cbs)
    if match(l:typename, l:pat) ==# -1 | continue | endif
    if type(l:Cbs) ==# v:t_func
      call l:Cbs(a:msg)
      continue
    endif
    for l:Cb in l:Cbs
      call l:Cb(a:msg)
    endfor
  endfor
endfunction

" BRIEF:  Make a request of the debug adapter.
function! dapper#MiddleTalker#request(command, request_args, Callback) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  if type(a:request_args) !=# v:t_dict || type(a:Callback) !=# v:t_func
    throw '(dapper#MiddleTalker) Bad argument types (should be '
      \.v:t_dict.', '.v:t_func.'): '
      \.type(a:request_args).', '.type(a:Callback)
  endif
  let l:req_args = deepcopy(a:request_args)
  " set vim_id but not vim_msg_typename: since this message is outgoing and
  " the latter isn't needed on the middle-end, vim_msg_typename shouldn't matter
  let l:vim_id = l:self.__getID()
  let l:self['__ids_to_callbacks'][l:vim_id] = a:Callback
  call DapperRequest(a:command, l:vim_id, l:req_args)
endfunction

" BRIEF:  Register a subscription to messages whose typenames match a pattern.
" PARAM:  name_pattern  (v:t_string)  Regex pattern against which to match
"                                     typenames.
" PARAM:  Callback      (v:t_func)    When a message matches a pattern, call
"                                     this function with that message as a
"                                     parameter.
function! dapper#MiddleTalker#subscribe(name_pattern, Callback) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  if type(a:name_pattern) !=# v:t_string || type(a:Callback) !=# v:t_func
    throw '(dapper#MiddleTalker) Bad argument types (should be '
      \.v:t_string.', '.v:t_func.'): '
      \.type(a:name_pattern).', '.type(a:Callback)
  endif
  let l:subs = l:self['__patterns_to_callbacks']
  if has_key(l:subs, a:name_pattern)
    " allow multiple subscribers to a single pattern
    if type(l:subs[a:name_pattern]) == v:t_list
      let l:subs[a:name_pattern] += [a:Callback]
    else
      let l:callbacks = [l:subs[a:name_pattern], a:Callback]
      let l:subs[a:name_pattern] = l:callbacks
    endif
  else
    let l:subs[a:name_pattern] = a:Callback
  endif
endfunction

" BRIEF:  Cancel a subscription.
" RETURN: (v:t_bool)    `v:true` when a matching subscription was successfully
"                       removed, `v:false` otherwise.
" PARAM:  name_pattern  (v:t_string)  The original regex pattern used to
"                                     register the subscription.
" PARAM:  Callback      (v:t_func)    A Funcref that compares equal with that
"                                     of the original subscription.
function! dapper#MiddleTalker#unsubscribe(name_pattern, Callback) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  let l:subs = l:self['__patterns_to_callbacks']
  if !has_key(l:subs, a:name_pattern) | return v:false | endif
  let l:Cbs = l:subs[a:name_pattern]

  if type(l:Cbs) ==# v:t_list
    let l:i = index(l:Cbs, a:Callback)
    if l:i ==# -1 | return v:false | endif
    call remove(l:Cbs, l:i)
    return v:true
  endif

  if l:Cbs ==# a:Callback
    unlet l:subs[a:name_pattern]
    return v:true
  endif
  return v:false
endfunction

" BRIEF:  Send a report, which might be logged by a handler.
" PARAM:  kind  (v:t_string)
" PARAM:  brief (v:t_string)
" PARAM:  long  (v:t_string?)
" PARAM:  alert (v:t_bool?)
" PARAM:  other (any?)
function! dapper#MiddleTalker#notifyReport(kind, brief, ...) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  let l:msg = call('dapper#dap#Report#new', [0, '', a:kind, a:brief] + a:000)
  call l:self.receive(l:msg)
endfunction
