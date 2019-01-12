" BRIEF:  Represent breakpoints set on a particular function.

function! dapper#model#FunctionBreakpoints#new(message_passer) abort
  let l:new = dapper#model#Breakpoints#new()
  let l:new['TYPE']['SourceBreakpoints'] = 1
  let l:new['__message_passer'] = a:message_passer

  let l:new['_matchOn']     = { -> 'name'}
  let l:new['_matchOnType'] = { -> v:t_string}
  let l:new['_command']     = { -> 'setFunctionBreakpoints'}
  let l:new['_bpCtor']      = function('dapper#dap#FunctionBreakpoint#new')

  let l:new['_argsFromSelf'] =
      \ function('dapper#model#FunctionBreakpoints#_argsFromSelf')

  call a:message_passer.subscribe('SetFunctionBreakpointsResponse',
      \ function('dapper#model#Breakpoints#receive', l:new))
  return l:new
endfunction

function! dapper#model#FunctionBreakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'FunctionBreakpoints')
  try
    let l:err = '(dapper#model#FunctionBreakpoints) Object is not of type FunctionBreakpoints: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#FunctionBreakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURNS:  (v:t_list)  List of `DebugProtocol.FunctionBreakpoint`.
function! dapper#model#FunctionBreakpoints#breakpoints() abort dict
  call dapper#model#FunctionBreakpoints#CheckType(l:self)
  return deepcopy(l:self['_bps'])
endfunction

" BRIEF:  Set a breakpoint on a particular function.
" DETAILS:  Can also be used to edit an existing breakpoint, by specifying
"     the same function name as that breakpoint.
" PARAM:  props   (v:t_dict) Dictionary that may contain the following:
"
"     - name        (v:t_string)    The name of the function.
"     - condition   (v:t_string?)   An optional conditional expression.
"     - hitCondition (v:t_string?)  An expression controlling how many hits of
"         the breakpoint are ignored. Interpreted by the backend.
function! dapper#model#FunctionBreakpoints#setBreakpoint(props) abort dict
  throw 'ERROR(Failure) (dapper#model#FunctionBreakpoints) Called function that '
      \ . 'only exists for documentation: setBreakpoint'
endfunction

" BRIEF:  Remove a breakpoint set on the given function.
" RETURNS:  (v:t_list)  List of `DebugProtocol.FunctionBreakpoint & Breakpoint`;
"     all breakpoints that matched the given name.
function! dapper#model#FunctionBreakpoints#removeBreakpoint(name) abort dict
  throw 'ERROR(Failure) (dapper#model#FunctionBreakpoints) Called function that '
      \ . 'only exists for documentation: removeBreakpoint'
endfunction

function! dapper#model#FunctionBreakpoints#_argsFromSelf() abort dict
  call dapper#model#FunctionBreakpoints#CheckType(l:self)

  let l:args = dapper#dap#SetFunctionBreakpointsArguments#new()
  let l:args['breakpoints'] = l:self['_bps']

  return l:args
endfunction
