" BRIEF:  Represent those breakpoints set within a particular Source.

" BRIEF:  Construct a new SourceBreakpoints object.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  source  (DebugProtocol.Source)  The Source to which these
"     breakpoints belong.
function! dapper#model#SourceBreakpoints#new(message_passer, source, ...) abort
  let l:new = call('dapper#model#Breakpoints#new', [a:message_passer] + a:000)
  let l:new['TYPE']['SourceBreakpoints'] = 1
  let l:new['__source'] = deepcopy(a:source)

  let l:new['_matchOn']     = { -> 'line'}
  let l:new['_matchOnType'] = { -> v:t_number}
  let l:new['_command']     = { -> 'setBreakpoints'}
  let l:new['_bpCtor']      = function('dapper#dap#SourceBreakpoint#new')

  let l:new['_argsFromSelf'] =
      \ function('dapper#model#SourceBreakpoints#_argsFromSelf')

  call a:message_passer.subscribe('SetBreakpointsResponse',
      \ function('dapper#model#Breakpoints#receive', l:new))
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
  throw 'ERROR(Failure) (dapper#model#SourceBreakpoints) Called function that '
      \ . 'only exists for documentation: setBreakpoint'
endfunction

" BRIEF:  Remove a breakpoint from the source file.
" RETURNS:  (v:t_list)  List of `DebugProtocol.SourceBreakpoint & Breakpoint`;
"     all breakpoints that matched the given line number.
" PARAM:  line  (v:t_number)  The line number of the breakpoint to be removed.
function! dapper#model#SourceBreakpoints#removeBreakpoint(line) abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  throw 'ERROR(Failure) (dapper#model#SourceBreakpoints) Called function that '
      \ . 'only exists for documentation: removeBreakpoint'
endfunction

" RETURNS:  (DebugProtocol.SetBreakpointsArguments) Arguments for a
"     `SetBreakpointsRequest`, with the list of breakpoints taken from *this*
"     object's list of source breakpoints, and whose `source` is this object's
"     `Source`.
function! dapper#model#SourceBreakpoints#_argsFromSelf() abort dict
  call dapper#model#SourceBreakpoints#CheckType(l:self)
  let l:curr_bps = l:self['_bps']

  let l:args = dapper#dap#SetBreakpointsArguments#new()
  let l:args['source'] = l:self['__source']
  let l:args['breakpoints'] = l:curr_bps
  for l:bp in l:curr_bps  " also populate deprecated lines
    call add(l:args['lines'], l:bp['line'])
  endfor
  " TODO handle sourceModified?

  return l:args
endfunction
