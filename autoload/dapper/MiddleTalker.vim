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
let s:message_interface = dapper#dap#DapperMessage()

""
" @public
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
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction
call dapper#MiddleTalker#Interface()  " initialize interface

""
" @public
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
    \ '__logger': dapper#log#DebugLogger#Get(),
    \ '__GetID': typevim#make#Member('__GetID'),
    \ '__Log': typevim#make#Member('__Log'),
    \ 'VimifyMessage': typevim#make#Member('VimifyMessage'),
    \ 'Receive': typevim#make#Member('Receive'),
    \ 'Request': typevim#make#Member('Request'),
    \ 'Subscribe': typevim#make#Member('Subscribe'),
    \ 'Unsubscribe': typevim#make#Member('Unsubscribe'),
    \ 'NotifyReport': typevim#make#Member('NotifyReport')
  \ }

  call typevim#make#Class(s:typename, g:dapper_middletalker)
  return typevim#ensure#Implements(g:dapper_middletalker, s:interface)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict MiddleTalker
" Return a request ID number, guaranteed to be distinct from those of all
" existing requests.
function! dapper#MiddleTalker#__GetID() abort dict
  call s:CheckType(l:self)
  let l:self.__next_id += 1
  return l:self.__next_id
endfunction

""
" @public
" @dict MiddleTalker
" (Re)populate the `vim_msg_typename` and `vim_id` of the given {msg}, based
" on its type and other properties. `vim_id` is set to 0, if not present or
" not a number or string; is converted to a number (by "adding" 0) if a
" string; or left unmodified, if it's just a number.
"
" @throws BadValue if {msg} is a malformed ProtocolMessage.
" @throws WrongType if {msg} is not a dict, or is not a ProtocolMessage at all.
function! dapper#MiddleTalker#VimifyMessage(msg) abort
  if !exists('s:protocol_msg_interface')
    " as of time of writing, dapper#dap#ProtocolMessage includes
    " vim_msg_typename and vim_id for convenience; declare a 'proper'
    " ProtocolMessage without these two fields
    let s:protocol_msg_interface = {
        \ 'seq': typevim#Number(),
        \ 'type': typevim#String(),
        \ }
    call typevim#make#Interface('ProtocolMessage', s:protocol_msg_interface)
  endif
  call maktaba#ensure#IsDict(a:msg)
  call typevim#ensure#Implements(a:msg, s:protocol_msg_interface)
  let l:suffix = toupper(a:msg.type[0:0]).a:msg.type[1:]
  if maktaba#value#IsIn(a:msg.type, ['request', 'response'])
    if !has_key(a:msg, 'command')
      let l:prefix = ''
    else
      let l:prefix = a:msg.command
    endif
  elseif a:msg.type ==# 'event'
    if !has_key(a:msg, 'event')
      let l:prefix = ''
    else
      let l:prefix = a:msg.event
    endif
  elseif a:msg.type ==# 'report'
    if !has_key(a:msg, 'kind')
      let l:prefix = ''
    else
      let l:prefix = a:msg.kind
    endif
  endif
  if !empty(l:prefix)
    let l:prefix = toupper(l:prefix[0:0]).l:prefix[1:]
  endif
  let a:msg.vim_msg_typename = l:prefix.l:suffix
  if has_key(a:msg, 'vim_id')
    if maktaba#value#IsNumber(a:msg.vim_id)
    elseif maktaba#value#IsString(a:msg.vim_id)
      let a:msg.vim_id = a:msg.vim_id + 0
    else
      let a:msg.vim_id = 0
    endif
  else
    let a:msg.vim_id = 0
  endif
  return a:msg
endfunction

""
" @public
" @dict MiddleTalker
" Receive a response or event {msg}, passing it to subscribers.
" @throws WrongType if {msg} is not a dictionary, or if {msg} is not a @dict(DapperMessage).
function! dapper#MiddleTalker#Receive(msg) abort dict
  call s:CheckType(l:self)
  if !maktaba#value#IsDict(a:msg)
    call l:self.__Log(
        \ 'error',
        \ 'Received invalid message: '.typevim#object#ShallowPrint(a:msg),
        \ a:msg
        \ )
    endif
  if !typevim#value#Implements(a:msg, s:message_interface)
    call l:self.__Log(
        \ 'debug',
        \ 'Recvd message not a DapperMessage, vimifiying...',
        \ a:msg
        \ )
    call dapper#MiddleTalker#VimifyMessage(a:msg)
  endif
  if a:msg.type !=# 'report'
    call l:self.__Log(
        \ 'debug',
        \ 'MiddleTalker received a: '.a:msg.type,
        \ a:msg
        \ )
  endif
  let l:id = a:msg.vim_id
  if l:id ># 0 " msg is a response to a request
    let l:Cb = l:self.__ids_to_callbacks[l:id]
    call l:self.__Log(
        \ 'debug', 'MiddleTalker calling back: '.get(l:Cb, 'name'),
        \ l:Cb, a:msg)
    call  l:self.__ids_to_callbacks[l:id](a:msg)
    unlet l:self.__ids_to_callbacks[l:id]
  endif
  let l:pats_to_cbs = l:self.__patterns_to_callbacks
  let l:typename = a:msg.vim_msg_typename
  for [l:pat, l:Cbs] in items(l:pats_to_cbs)
    if match(l:typename, l:pat) ==# -1 | continue | endif
    if maktaba#value#IsFuncref(l:Cbs)
      call l:self.__Log(
          \ 'debug', 'MiddleTalker calling back: '.get(l:Cbs, 'name'),
          \ l:Cbs, a:msg)
      call l:Cbs(a:msg)
      continue
    endif
    for l:Cb in l:Cbs
      call l:self.__Log(
          \ 'debug', 'MiddleTalker calling back: '.get(l:Cb, 'name'),
          \ l:Cb, a:msg)
      call l:Cb(a:msg)
    endfor
  endfor
endfunction

""
" @public
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
  let l:self.__ids_to_callbacks[l:vim_id] = a:Callback
  call l:self.NotifyReport(
      \ 'info',
      \ 'Sending request: '.typevim#object#ShallowPrint(a:command),
      \ 'Given callback: '.typevim#object#ShallowPrint(a:Callback)
        \ . ', given args: '.typevim#object#ShallowPrint(a:request_args)
      \ )
  call DapperRequest(a:command, l:vim_id, l:req_args)
endfunction

""
" @public
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
  let l:subs = l:self.__patterns_to_callbacks
  call l:self.__Log(
      \ 'debug',
      \ 'Adding subscription to: '.string(a:name_pattern),
      \ a:Callback
      \ )
  if has_key(l:subs, a:name_pattern)
    " allow multiple subscribers to a single pattern
    if type(l:subs[a:name_pattern]) == v:t_list
      call add(l:subs[a:name_pattern], a:Callback)
    else
      let l:callbacks = [l:subs[a:name_pattern], a:Callback]
      let l:subs[a:name_pattern] = l:callbacks
    endif
  else
    let l:subs[a:name_pattern] = a:Callback
  endif
endfunction

""
" @public
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

  call l:self.__Log(
      \ 'debug',
      \ 'Trying to remove sub: '.string(a:name_pattern),
      \ a:Callback
      \ )

  let l:subs = l:self.__patterns_to_callbacks
  if !has_key(l:subs, a:name_pattern) | return 0 | endif
  let l:Cbs = l:subs[a:name_pattern]

  if type(l:Cbs) ==# v:t_list
    let l:i = index(l:Cbs, a:Callback)
    if l:i ==# -1 | return 0 | endif
    call remove(l:Cbs, l:i)
    return 1
  elseif l:Cbs ==# a:Callback
    unlet l:subs[a:name_pattern]
    return 1
  endif
  return 0
endfunction

""
" @public
" @dict MiddleTalker
" @usage {kind} {brief} [long] [alert] [other]
" Pass a @dict(DapperReport) to the attached @dict(DebugLogger), while also
" sending it to the appropriate subscribers.
function! dapper#MiddleTalker#NotifyReport(kind, brief, ...) abort dict
  call s:CheckType(l:self)
  " log the message
  call call(l:self.__logger.NotifyReport, [a:kind, a:brief] + a:000)

  " pass it to subscribers
  let l:msg = call('dapper#dap#DapperReport#New', [a:kind, a:brief] + a:000)
  call l:self.Receive(l:msg)
endfunction

""
" @dict MiddleTalker
" @usage {kind} {brief} [long] [alert] [other]
" Pass a @dict(DapperReport) to the attached @dict(DebugLogger). Used
" internally for debug logging by MiddleTalker.
function! dapper#MiddleTalker#__Log(kind, brief, ...) abort dict
  call s:CheckType(l:self)
  call call(l:self.__logger.NotifyReport, [a:kind, a:brief] + a:000)
endfunction
