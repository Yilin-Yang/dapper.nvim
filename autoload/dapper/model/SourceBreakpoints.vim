" BRIEF:  Represent those breakpoints set within a particular Source.

" BRIEF:  Construct a new SourceBreakpoints object
" PARAM:  message_passer  (dapper#MiddleTalker)
function! dapper#model#SourceBreakpoints#new(message_passer) abort
  let l:new = dapper#model#Breakpoints#new()
  let l:new['TYPE']['SourceBreakpoints'] = 1
  let l:new['__message_passer'] = a:message_passer

  " line numbers to `DebugProtocol.SourceBreakpoint`s
  let l:new['__line_nos_to_bps'] = {}

  let l:new['setBreakpoint'] =
      \ function('dapper#model#SourceBreakpoints#setBreakpoint')
  let l:new['removeBreakpoint'] =
      \ function('dapper#model#SourceBreakpoints#removeBreakpoint')
  let l:new['clearBreakpoints'] =
      \ function('dapper#model#SourceBreakpoints#clearBreakpoints')

  let l:new['receive'] =
      \ function('dapper#model#SourceBreakpoints#receive')

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

" BRIEF:  Set a breakpoint on a line of a source file.
" PARAM:  props   (v:t_dict)  Dictionary that may contain the following
"     properties:
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
  if type(a:props !=# v:t_dict)
    throw 'ERROR(WrongType) (dapper#model#SourceBreakpoints) Arg isn''t dict:'
        \ . dapper#helpers#StrDump(a:props)
  endif
  if !has_key(a:props, 'line')
    throw "ERROR(WrongType) (dapper#model#SourceBreakpoints) Didn't give line: "
        \ . dapper#helpers#StrDump(a:props)
  endif
  let l:args = dapper#dap#SourceBreakpoint#new()
  for [l:prop, l:val] in items(a:props)
    if !has_key(l:args, l:prop) | continue | endif
    let l:args[l:prop] = l:val
  endfor

  let l:lines_to_bps = l:self['__line_nos_to_bps']
  let l:lines_to_bps[l:args['line']] = l:args
  let l:bps = values(l:lines_to_bps)

  call l:self['__message_passer'].request(
      \ 'setBreakpoints',
      \ l:lines_to_bps,
      \ function('dapper#model#SourceBreakpoints#receive', l:self)
      \ )
  call l:self.unfulfill()
endfunction

" BRIEF:  Remove a breakpoint from the source file.
" PARAM:  line  (v:t_number)  The line number of the breakpoint to be removed.
function! dapper#model#SourceBreakpoints#removeBreakpoint(line) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
endfunction

function! dapper#model#SourceBreakpoints#clearBreakpoints() abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
endfunction

" BRIEF:  Update from a `SetBreakpointsResponse` message.
" DETAILS:  Announcing that a given breakpoint failed to set is handled by
"     `BreakpointsHandler`.
function! dapper#model#SourceBreakpoints#receive(msg) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  " TODO update from the incoming message, use extends()
  call l:self.fulfill(l:self)
endfunction
