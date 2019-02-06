" BRIEF:  Abstract interface for getting/setting breakpoints of a certain type.
" DETAILS:  A `Breakpoints` is also a `Promise`: it is 'fulfilled' whenever
"     the last action (e.g. setting breakpoints, etc.) has been met with a
"     response from the debug adapter. Subscribing to a `Breakpoints` object
"     will notify the subscriber of updates to the `Breakpoints` object's
"     state.

" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#Breakpoints#new(message_passer, ...) abort
  let l:new = call('dapper#Promise#new', a:000)
  let l:new['TYPE']['Breakpoints'] = 1
  let l:new['__message_passer'] = a:message_passer

  let l:new['_bps'] = []

  let l:new['breakpoints'] =
      \ function('dapper#model#Breakpoints#breakpoints')
  let l:new['setBreakpoint'] =
      \ function('dapper#model#Breakpoints#setBreakpoint')
  let l:new['removeBreakpoint'] =
      \ function('dapper#model#Breakpoints#removeBreakpoint')
  let l:new['clearBreakpoints'] =
      \ function('dapper#model#Breakpoints#clearBreakpoints')
  let l:new['Receive'] =
      \ function('dapper#model#Breakpoints#Receive')

  " the property on which to compare breakpoints to see if they're 'the same'
  let l:new['_matchOn'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['_matchOn'])

  " the type of `_matchOn`; used for type checking
  let l:new['_matchOnType'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['_matchOnType'])

  " the command to be sent in requests
  let l:new['_command'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['_command'])

  " the constructor for the `Set*BreakpointsArgs` type
  let l:new['_argsFromSelf'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['_argsFromSelf'])

  " the constructor for the `*Breakpoint` type
  let l:new['_bpCtor'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['_bpCtor'])

  return l:new
endfunction

function! dapper#model#Breakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Breakpoints')
  try
    let l:err = '(dapper#model#Breakpoints) Object is not of type Breakpoints: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#Breakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#model#Breakpoints#__noImpl(funcname, ...) abort dict
  call dapper#model#Breakpoints#CheckType(l:self)
  throw 'ERROR(NotFound) No implementation for virtual func: '.a:funcname
endfunction

" BRIEF:  Get the breakpoints held by this object.
" RETURNS:  (v:t_list) List of `DebugProtocol.(*)Breakpoint`
function! dapper#model#Breakpoints#breakpoints() abort dict
  call dapper#model#Breakpoints#CheckType(l:self)
  return deepcopy(l:self['_bps'])
endfunction

" BRIEF:  Set a new breakpoint (by sending a request to the debug adapter.)
" PARAM:  props (v:t_dict)  The properties of the breakpoint to be set.
function! dapper#model#Breakpoints#setBreakpoint(props) abort dict
  call dapper#model#Breakpoints#CheckType(l:self)
  if type(a:props) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#model#Breakpoints) Arg isn''t dict:'
        \ . typevim#object#ShallowPrint(a:props)
  endif
  let l:match_prop = l:self._matchOn()
  if !has_key(a:props, l:match_prop)
    throw "ERROR(WrongType) (dapper#model#Breakpoints) Didn't give "
        \ .l:match_prop.': '.typevim#object#ShallowPrint(a:props)
  endif
  if type(a:props[l:match_prop]) !=# l:self._matchOnType()
    throw 'ERROR(WrongType) (dapper#model#Breakpoints) Bad type for match '
        \ .'property: '.l:match_prop.' in '.typevim#object#ShallowPrint(a:props)
  endif

  " search for existing, matching breakpoints
  let l:curr_bps = l:self['_bps']
  let l:target = {}
  for l:bp in l:curr_bps
    if l:bp[l:match_prop] ==# a:props[l:match_prop]
      let l:target = l:bp
      break
    endif
  endfor

  if empty(l:target)  " is a new breakpoint
    let l:target = l:self._bpCtor()  " construct new breakpoint object
    call add(l:curr_bps, l:target)   " add this breakpoint to our list
  endif

  " assign given properties into the breakpoint object
  for [l:prop, l:val] in items(a:props)
    if !has_key(l:target, l:prop) | continue | endif
    let l:target[l:prop] = l:val
  endfor

  " construct a Set*BreakpointArguments object
  let l:args = l:self._argsFromSelf()
  call l:self['__message_passer'].Request(
      \ l:self._command(),
      \ l:args,
      \ function('dapper#model#Breakpoints#Receive', l:self)
      \ )

  call l:self.unfulfill()
endfunction

" BRIEF:  Remove a set breakpoint (by sending a request to the debug adapter.)
" PARAM:  key (...) Search parameter to find the breakpoint(s) to be removed.
function! dapper#model#Breakpoints#removeBreakpoint(key) abort dict
  call dapper#model#Breakpoints#CheckType(l:self)
  if type(a:key) !=# l:self._matchOnType()
    throw 'ERROR(WrongType) (dapper#model#Breakpoints) Given key '
        \ . 'has the wrong type: ' . typevim#object#ShallowPrint(a:key)
  endif

  " search for matching breakpoints
  let l:match_prop = l:self._matchOn()
  let l:removed = []
  let l:bps = l:self['_bps']
  let l:i = 0 | while l:i <# len(l:bps)
    let l:bp = l:bps[l:i]
    if a:key ==# l:bp[l:match_prop]
      call add(l:removed, l:bp)
      unlet l:bps[l:i]
    else
      let l:i += 1
    endif
  endwhile

  " return empty list if no matching breakpoints were found
  if empty(l:removed) | return l:removed | endif

  " send new, 'pruned' list of breakpoints in a request
  let l:args = l:self._argsFromSelf()
  call l:self['__message_passer'].Request(
      \ l:self._command(),
      \ l:args,
      \ function('dapper#model#Breakpoints#Receive', l:self)
      \ )
  call l:self.unfulfill()

  return l:removed
endfunction

" BRIEF:  Clear all breakpoints of this type.
function! dapper#model#Breakpoints#clearBreakpoints() abort dict
  call dapper#model#Breakpoints#CheckType(l:self)
  let l:self['_bps'] = []
  let l:args = l:self._argsFromSelf()
  call l:self['__message_passer'].Request(
      \ l:self._command(),
      \ l:args,
      \ function('dapper#model#Breakpoints#Receive', l:self)
      \ )
  call l:self.unfulfill()
endfunction

" BRIEF:  Update from a `Set(*)BreakpointsResponse` message.
" DETAILS:  Announcing that a given breakpoint failed to set is handled by
"     `BreakpointsHandler`.
let s:bp_props = ['id', 'source', 'line', 'column', 'endLine', 'endColumn']
function! dapper#model#Breakpoints#Receive(msg) abort dict
  call dapper#model#Breakpoints#CheckType(l:self)

  call l:self['__message_passer'].NotifyReport(
      \ 'status', 'Received '.a:msg['vim_msg_typename'].'.', a:msg)

  let l:resp = a:msg['body']['breakpoints']
  let l:bps = l:self['_bps']
  if len(l:resp) !=# len(l:bps)
    throw 'ERROR(Failure) (dapper#model#Breakpoints) '
        \ . 'Mismatched array sizes, sent breakpoints vs. breakpoints received:'
        \ . typevim#object#ShallowPrint(l:bps) . ', '
        \ . typevim#object#ShallowPrint(a:msg)
  endif

  " update our current breakpoints from the response message
  let l:idx_to_wipeout = []
  let l:i = 0 | while l:i <# len(l:resp)
    let l:curr = l:bps[l:i]
    let l:real = l:resp[l:i]
    if !l:real['verified']  " breakpoint not set
      call add(l:idx_to_wipeout, l:i)
      let l:i += 1
      continue  " don't process this (invalid) breakpoint
    endif
    for l:prop in s:bp_props  " breakpoint set successfully
      if !has_key(l:real, l:prop) | continue | endif
      let l:curr[l:prop] = l:real[l:prop]
    endfor
  let l:i += 1 | endwhile

  " delete breakpoints that weren't set successfully
  call reverse(l:idx_to_wipeout)  " delete items 'back-to-front'
  for l:i in l:idx_to_wipeout
    unlet l:bps[l:i]
  endfor

  call l:self.fulfill(l:self)
endfunction
