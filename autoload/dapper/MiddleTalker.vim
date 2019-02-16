""
" @dict MiddleTalker
" The connection between dapper.nvim's VimL frontend and its TypeScript
" "middle-end". Provides a subscription-based interface for sending requests
" to and receiving messages from the middle-end through neovim's remote plugin
" |RPC|, in a manner comparable to a Node.js-style `EventEmitter` object.
"
" Objects can subscribe to messages whose `"vim_msg_typename"` matches a given
" regex pattern: MiddleTalker will, on receiving a matching message, call the
" subscriber's provided callback function with that matching message. Objects
" may also send requests: MiddleTalker will note the sender of the request,
" and if it receives a response, will return that request to the sender (and
" to any other objects subscribed to messages of that type).
"
" MiddleTalker is a singleton. Because MiddleTalker encapsulates neovim's
" program-wide RPC, it does not make sense to have multiple MiddleTalker
" instances at a given time.

let s:typename = 'MiddleTalker'

""
" @function dapper#MiddleTalker#Interface()
" @dict MiddleTalker
" Returns the interface that MiddleTalker implements.
function! dapper#MiddleTalker#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'Request': typevim#Func(),
        \ 'Subscribe': typevim#Func(),
        \ 'Unsubscribe': typevim#Func(),
        \ 'NotifyReport': typevim#Func(),
        \ }
    call typevim#make#Interface('MiddleTalker', s:interface)
  endif
  return s:interface
endfunction
call dapper#MiddleTalker#Interface()  " initialize interface

""
" @function dapper#MiddleTalker#get()
" @dict MiddleTalker
" Get the MiddleTalker singleton, or make one if it doesn't yet exist.
function! dapper#MiddleTalker#Get() abort
  if exists('g:dapper_middletalker')
    if typevim#value#IsType(g:dapper_middletalker, s:typename)
        \ && typevim#value#Implements(g:dapper_middletalker, s:interface)
      " already exists
      return g:dapper_middletalker
    endif
    " invalid object, okay to overwrite
  endif

  let g:dapper_middletalker = {
    \ 'TYPE': {'MiddleTalker': 1},
    \ '__next_id': 0,
    \ '__patterns_to_callbacks': {},
    \ '__ids_to_callbacks': {},
    \ '__GetID': typevim#make#Member('__GetID'),
    \ 'Receive': typevim#make#Member('Receive'),
    \ 'Request': typevim#make#Member('Request'),
    \ 'Subscribe': typevim#make#Member('Subscribe'),
    \ 'Unsubscribe': typevim#make#Member('Unsubscribe'),
    \ 'NotifyReport': typevim#make#Member('NotifyReport')
  \ }

  call typevim#make#Class(s:typename, g:dapper_middletalker)
  return typevim#ensure#Implements(g:dapper_middletalker, s:interface)
endfunction

function s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict MiddleTalker
" Return a request ID number, guaranteed to be distinct from those of all
" existing requests.
function! dapper#MiddleTalker#__GetID() abort dict
  call s:CheckType(l:self)
  let l:self['__next_id'] += 1
  return l:self['__next_id']
endfunction

""
" @dict MiddleTalker
" Receive a response or event {msg}, passing it to subscribers.
" @throws WrongType if {msg} is not a dictionary.
function! dapper#MiddleTalker#Receive(msg) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsDict(a:msg)
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

""
" @dict MiddleTalker
" Make a request of the debug adapter. {command} is the `"command"` property
" of a DAP Request; {request_args} is the `"[blank]RequestArguments"` object
" associated with that request type; and {Callback} is the function that the
" MiddleTalker should call after receiving a response to this request.
"
" @throws WrongType if {command} is not a string, {request_args} is not a dict, or if {Callback} is not a |Funcref|.
function! dapper#MiddleTalker#Request(command, request_args, Callback) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:command)
  call maktaba#ensure#IsDict(a:request_args)
  call maktaba#ensure#IsFuncref(a:Callback)
  let l:req_args = deepcopy(a:request_args)
  " set vim_id but not vim_msg_typename: since this message is outgoing and
  " the latter isn't needed on the middle-end, vim_msg_typename shouldn't matter
  let l:vim_id = l:self.__GetID()
  let l:self['__ids_to_callbacks'][l:vim_id] = a:Callback
  call l:self.NotifyReport(
      \ 'status',
      \ 'Sending request: '.typevim#object#ShallowPrint(a:command),
      \ 'Given callback: '.typevim#object#ShallowPrint(a:Callback)
        \ . ', given args: '.typevim#object#ShallowPrint(a:request_args)
      \ )
  call DapperRequest(a:command, l:vim_id, l:req_args)
endfunction

""
" @dict MiddleTalker
" Register a subscription to messages whose typenames match a {name_pattern},
" a regular expression used to |string-match| against the `"vim_msg_typename"`
" of an incoming message. `"vim_msg_typename"` is a construct of dapper.nvim,
" not of the DAP itself: the middle-end annotates front-going DAP messages
" with a straightforward "human-readable" typename (e.g. a LaunchRequestArgument
" has the `"vim_msg_typename"`: `"LaunchRequestArgument"`).
"
" When {name_pattern} matches against an incoming messages
" `"vim_msg_typename"`, the MiddleTalker will call {Callback}.
"
" @throws WrongType if {name_pattern} is not a string, or if {Callback} is not a |Funcref|.
function! dapper#MiddleTalker#Subscribe(name_pattern, Callback) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:name_pattern)
  call maktaba#ensure#IsFuncref(a:Callback)
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

""
" @dict MiddleTalker
" Cancel a subscription, returning 1 when a matching subscription was
" successfully removed, and 0 otherwise.
"
" {name_pattern} and {Callback} are exactly the same as in
" @function(MiddleTalker.Subscribe); in fact, they should be exactly the same
" as the original arguments (i.e. should compare equal by |expr-==#|) provided
" when the subscription was originally registered.
"
" @throws WrongType if {name_pattern} is not a string, or if {Callback} is not a |Funcref|.
function! dapper#MiddleTalker#Unsubscribe(name_pattern, Callback) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:name_pattern)
  call maktaba#ensure#IsFuncref(a:Callback)
  let l:subs = l:self['__patterns_to_callbacks']
  if !has_key(l:subs, a:name_pattern) | return 0 | endif
  let l:Cbs = l:subs[a:name_pattern]

  if type(l:Cbs) ==# v:t_list
    let l:i = index(l:Cbs, a:Callback)
    if l:i ==# -1 | return 0 | endif
    call remove(l:Cbs, l:i)
    return 1
  endif

  if l:Cbs ==# a:Callback
    unlet l:subs[a:name_pattern]
    return 1
  endif
  return 0
endfunction

""
" @dict MiddleTalker
" @usage {kind} {brief} [long] [alert] [other]
" Broadcast a @dict(Report) constructed using the given arguments, which might
" be logged by a subscribed @dict(ReportHandler).
"
" @throws WrongType if {kind} or {brief} are not strings. The remaining arguments may be of any type.
function! dapper#MiddleTalker#NotifyReport(kind, brief, ...) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:kind)
  call maktaba#ensure#IsString(a:brief)
  let l:msg = call('dapper#dap#Report#new', [0, '', a:kind, a:brief] + a:000)
  call l:self.Receive(l:msg)
endfunction
