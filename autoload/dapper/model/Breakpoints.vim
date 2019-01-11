" BRIEF:  Abstract interface for getting/setting breakpoints of a certain type.
" DETAILS:  A `Breakpoints` is also a `Promise`: it is 'fulfilled' whenever
"     the last action (e.g. setting breakpoints, etc.) has been met with a
"     response from the debug adapter. Subscribing to a `Breakpoints` object
"     will notify the subscriber of updates to the `Breakpoints` object's
"     state.

" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#Breakpoints#new(...) abort
  let l:new = call('dapper#Promise#new', a:000)
  let l:new['TYPE']['Breakpoints'] = 1
  let l:new['setBreakpoint'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['setBreakpoint']),
  let l:new['removeBreakpoint'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['removeBreakpoint']),
  let l:new['clearBreakpoints'] =
      \ function('dapper#model#Breakpoints#__noImpl', ['clearBreakpoints']),
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

" BRIEF:  Set a new breakpoint (by sending a request to the debug adapter.)
" PARAM:  (variadic)  Dependent on the kind of breakpoint being set.
function! dapper#model#Breakpoints#setBreakpoint(...) abort dict
  throw 'ERROR(NotFound) No implementation for virtual func: setBreakpoint'
endfunction

" BRIEF:  Remove a set breakpoint (by sending a request to the debug adapter.)
" PARAM:  (variadic)  Search parameters to find the breakpoint(s) to be removed.
function! dapper#model#Breakpoints#removeBreakpoint(...) abort dict
  throw 'ERROR(NotFound) No implementation for virtual func: removeBreakpoint'
endfunction

" BRIEF:  Clear all breakpoints of this type.
function! dapper#model#Breakpoints#clearBreakpoints() abort dict
  throw 'ERROR(NotFound) No implementation for virtual func: clearBreakpoints'
endfunction
