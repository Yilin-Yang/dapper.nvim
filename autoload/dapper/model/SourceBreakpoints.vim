" BRIEF:  Represent those breakpoints set within a particular Source.

" BRIEF:  Construct a new SourceBreakpoints object
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  source  (DebugProtocol.Source)  The Source to which these
"     breakpoints belong.
function! dapper#model#SourceBreakpoints#new(message_passer, source) abort
  let l:new = dapper#model#Breakpoints#new()
  let l:new['TYPE']['SourceBreakpoints'] = 1
  let l:new['__message_passer'] = a:message_passer
  let l:new['__source'] = deepcopy(a:source)

  " list of `DebugProtocol.SourceBreakpoint`s
  let l:new['__bps'] = []

  let l:new['breakpoints'] =
      \ function('dapper#model#SourceBreakpoints#breakpoints')
  let l:new['setBreakpoint'] =
      \ function('dapper#model#SourceBreakpoints#setBreakpoint')
  let l:new['removeBreakpoint'] =
      \ function('dapper#model#SourceBreakpoints#removeBreakpoint')
  let l:new['clearBreakpoints'] =
      \ function('dapper#model#SourceBreakpoints#clearBreakpoints')

  let l:new['receive'] =
      \ function('dapper#model#SourceBreakpoints#receive')

  let l:new['_argsFromSelf'] =
      \ function('dapper#model#SourceBreakpoints#_argsFromSelf')

  call a:message_passer.subscribe('SetBreakpointsResponse',
      \ function('dapper#model#SourceBreakpoints#receive', l:new))
  return l:new
endfunction

function! dapper#model#SourceBreakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SourceBreakpoints')
  try
    let l:err = '(dapper#model#SourceBreakpoints) Object is not of type SourceBreakpoints: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#SourceBreakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURNS:  (v:t_list)  List of `DebugProtocol.SourceBreakpoint`.
function! dapper#model#SourceBreakpoints#breakpoints() abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  return deepcopy(l:self['__bps'])
endfunction

" BRIEF:  Set a breakpoint on a line of a source file.
" DETAILS:  Can also be used to edit an existing breakpoint, by specifying
"     that breakpoint's line number.
" PARAM:  props   (v:t_dict)  Dictionary that may contain the following;
"
"     - line (v:t_number) *Required*. The line number on which to set the
"         breakpoint.
"     - column (v:t_number?)  The column number of the breakpoint.
"     - condition (v:t_string?)     An expression that should evaluate
"         to `true` in the debugged program before the debugger should stop on
"         that breakpoint.
"     - hitCondition  (v:t_string?) How many hits of the breakpoint to ignore.
"         Interpreted by the debug adapter backend.
"     - logMessage    (v:t_string?) If present and nonempty, instead of
"         stopping on the breakpoint, the debug adapter should log this
"         message. Expressions enclosed in curly braces (i.e. `{}`) are
"         interpolated.
function! dapper#model#SourceBreakpoints#setBreakpoint(props) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  if type(a:props) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#model#SourceBreakpoints) Arg isn''t dict:'
        \ . dapper#helpers#StrDump(a:props)
  endif
  if !has_key(a:props, 'line')
    throw "ERROR(WrongType) (dapper#model#SourceBreakpoints) Didn't give line: "
        \ . dapper#helpers#StrDump(a:props)
  endif

  " search for existing breakpoints with this line number
  let l:curr_bps = l:self['__bps']
  let l:target = {}
  for l:bp in l:curr_bps
    if l:bp['line'] ==# a:props['line']
      let l:target = l:bp
      break
    endif
  endfor

  if empty(l:target)  " is a new breakpoint
    let l:target = dapper#dap#SourceBreakpoint#new()
  call add(l:curr_bps, l:target)  " add this breakpoint to our list
  endif

  for [l:prop, l:val] in items(a:props)
    if !has_key(l:target, l:prop) | continue | endif
    let l:target[l:prop] = l:val
  endfor

  let l:args = l:self._argsFromSelf()
  call l:self['__message_passer'].request(
      \ 'setBreakpoints',
      \ l:args,
      \ function('dapper#model#SourceBreakpoints#receive', l:self)
      \ )

  call l:self.unfulfill()
endfunction

" BRIEF:  Remove a breakpoint from the source file.
" RETURNS:  (v:t_list)  List of `DebugProtocol.SourceBreakpoint & Breakpoint`;
"     all breakpoints that matched the given line number.
" PARAM:  line  (v:t_number)  The line number of the breakpoint to be removed.
function! dapper#model#SourceBreakpoints#removeBreakpoint(line) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  if type(a:line) !=# v:t_number
    throw 'ERROR(WrongType) (dapper#model#SourceBreakpoints) Given line number '
        \ . 'isn''t a number: ' . dapper#helpers#StrDump(a:line)
  endif
  let l:removed = []
  let l:bps = l:self['__bps']
  let l:i = 0 | while l:i <# len(l:bps)
    let l:bp = l:bps[l:i]
    if a:line ==# l:bp['line']
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
  call l:self['__message_passer'].request(
      \ 'setBreakpoints',
      \ l:args,
      \ function('dapper#model#SourceBreakpoints#receive', l:self)
      \ )
  call l:self.unfulfill()

  return l:removed
endfunction

" BRIEF:  Clear all breakpoints from the source file.
function! dapper#model#SourceBreakpoints#clearBreakpoints() abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  let l:self['__bps'] = []
  let l:args = l:self._argsFromSelf()
  call l:self['__message_passer'].request(
      \ 'setBreakpoints',
      \ l:args,
      \ function('dapper#model#SourceBreakpoints#receive', l:self)
      \ )
  call l:self.unfulfill()
endfunction

" BRIEF:  Update from a `SetBreakpointsResponse` message.
" DETAILS:  Announcing that a given breakpoint failed to set is handled by
"     `BreakpointsHandler`.
let s:bp_props = ['id', 'source', 'line', 'column', 'endLine', 'endColumn']
function! dapper#model#SourceBreakpoints#receive(msg) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)

  call l:self['__message_passer'].notifyReport(
      \ 'status', 'Received SetBreakpointsResponse.', a:msg)

  let l:resp = a:msg['body']['breakpoints']
  let l:bps = l:self['__bps']
  if len(l:resp) !=# len(l:bps)
    throw 'ERROR(Failure) (dapper#model#SourceBreakpoints) '
        \ . 'Mismatched array sizes, sent breakpoints vs. breakpoints received:'
        \ . dapper#helpers#StrDump(l:bps) . ', '
        \ . dapper#helpers#StrDump(a:msg)
  endif

  " update our current breakpoints from the response message
  let l:idx_to_wipeout = []
  let l:i = 0 | while l:i <# len(l:resp)
    let l:curr = l:bps[l:i]
    let l:real = l:resp[l:i]
    if !l:real['verified']  " breakpoint not set
      call add(l:idx_to_wipeout, l:i)
      let l:i += 1
      continue
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

" RETURNS:  (DebugProtocol.SetBreakpointsArguments) Arguments for a
"     `SetBreakpointsRequest`, with the list of breakpoints taken from *this*
"     object's list of source breakpoints, and whose `source` is this object's
"     `Source`.
function! dapper#model#SourceBreakpoints#_argsFromSelf() abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  let l:curr_bps = l:self['__bps']

  let l:args = dapper#dap#SetBreakpointsArguments#new()
  let l:args['source'] = l:self['__source']
  let l:args['breakpoints'] = l:curr_bps
  for l:bp in l:curr_bps  " also populate deprecated lines
    call add(l:args['lines'], l:bp['line'])
  endfor
  " TODO handle sourceModified?

  return l:args
endfunction
