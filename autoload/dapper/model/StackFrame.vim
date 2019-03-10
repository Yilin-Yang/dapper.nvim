""
" @dict StackFrame
" Stores the scopes for a particular stack frame in a thread's callstack.

let s:typename = 'StackFrame'

""
" @public
" @function dapper#model#StackFrame#New({message_passer}, {stack_frame}, {scopes_response})
" @dict StackFrame
" Construct a new StackFrame object.
"
" @throws BadValue if {stack_frame}, {scopes_response}, or {message_passer} are not dicts.
" @throws WrongType if {stack_frame} is not a DebugProtocol.StackFrame, {scopes_response} is not a ScopesResponse, or if {message_passer} does not implement a @dict(MiddleTalker) interface.
function! dapper#model#StackFrame#New(message_passer, stack_frame, scopes_response) abort
  call typevim#ensure#Implements(
      \ a:stack_frame, dapper#dap#StackFrame())
  call typevim#ensure#Implements(
      \ a:scopes_response, dapper#dap#ScopesResponse())
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_raw_scopes': v:null,
      \ '_names_to_scopes': {},
      \ '_stack_frame': a:stack_frame,
      \ 'id': typevim#make#Member('id'),
      \ 'name': typevim#make#Member('name'),
      \ 'source': typevim#make#Member('source'),
      \ 'line': typevim#make#Member('line'),
      \ 'column': typevim#make#Member('column'),
      \ 'endLine': typevim#make#Member('endLine'),
      \ 'endColumn': typevim#make#Member('endColumn'),
      \ 'moduleId': typevim#make#Member('moduleId'),
      \ 'presentationHint': typevim#make#Member('presentationHint'),
      \
      \ '_HandleVariablesResponse': typevim#make#Member('_HandleVariablesResponse'),
      \ 'scope': typevim#make#Member('scope'),
      \ 'scopes': typevim#make#Member('scopes'),
      \ }
  call typevim#make#Class(s:typename, l:new)
  let l:new._raw_scopes =
      \ s:ValidateScopes(l:new, copy(a:scopes_response.body.scopes))
  let l:new._HandleVariablesResponse =
      \ typevim#object#Bind(l:new._HandleVariablesResponse, l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict StackFrame
" Check that the given list of {scopes} is comprised of DebugProtocol.Scope
" structures. If not, log the validation failure through {self} and discard
" the offending DebugProtocol.Scope "in place". Returns the validated list
" afterwards for convenience.
"
" @throws BadValue if {self} is not a dict.
" @throws WrongType if {self} is not a StackFrame or {response} is not a list.
function! s:ValidateScopes(self, scopes) abort
  call s:CheckType(a:self)
  call maktaba#ensure#IsList(a:scopes)
  let l:i = 0 | while l:i <# len(a:scopes)
    let l:scope = a:scopes[l:i]
    if typevim#value#Implements(l:scope, dapper#dap#Scope())
      let l:i += 1
      continue
    endif
    call a:self._message_passer.NotifyReport(
        \ 'error',
        \ 'Got malformed scope in stack frame lookup!',
        \ l:scope,
        \ a:scopes
        \ )
    unlet a:scopes[l:i]
  let l:i += 1 | endwhile
  return a:scopes
endfunction

""
" Return {property} of {self}, if present. Else, throw an ERROR(NotFound).
function! s:ReturnPropIfPresent(self, property) abort
  call s:CheckType(a:self)
  call maktaba#ensure#IsString(a:property)
  if has_key(a:self._stack_frame, a:property)
    return a:self._stack_frame[a:property]
  endif
  throw maktaba#error#NotFound(
      \ 'Could not find property %s in StackFrame; it might be optional?',
      \ a:property)
endfunction

""
" @public
" @dict StackFrame
" Return a unique identifier for the stack frame.
" @throws NotFound if no id can be found.
function! dapper#model#StackFrame#id() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'id')
endfunction

""
" @public
" @dict StackFrame
" Return the name of the stack frame.
" @throws NotFound if no name can be found.
function! dapper#model#StackFrame#name() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'name')
endfunction

""
" @public
" @dict StackFrame
" Return the DebugProtocol.Source associated with this stack frame.
" @throws NotFound if no source can be found.
function! dapper#model#StackFrame#source() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'source')
endfunction

""
" @public
" @dict StackFrame
" Return the line number associated with this stack frame.
" @throws NotFound if no line can be found.
function! dapper#model#StackFrame#line() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'line')
endfunction

""
" @public
" @dict StackFrame
" Return the column number associated with this stack frame.
" @throws NotFound if no column can be found.
function! dapper#model#StackFrame#column() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'column')
endfunction

""
" @public
" @dict StackFrame
" Return the final line number associated with this stack frame.
" @throws NotFound if no endLine can be found.
function! dapper#model#StackFrame#endLine() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'endLine')
endfunction

""
" @public
" @dict StackFrame
" Return the final column number associated with this stack frame.
" @throws NotFound if no endColumn can be found.
function! dapper#model#StackFrame#endColumn() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'endColumn')
endfunction

""
" @public
" @dict StackFrame
" Return the name of the module (e.g. Node.js module, external library, etc.)
" associated with this stack frame.
" @throws NotFound if no moduleId can be found.
function! dapper#model#StackFrame#moduleId() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'moduleId')
endfunction

""
" @public
" @dict StackFrame
" @throws NotFound if no presentationHint can be found.
function! dapper#model#StackFrame#presentationHint() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'presentationHint')
endfunction

""
" @public
" @dict StackFrame
" Return a list of the names of all scopes accessible from this StackFrame.
function! dapper#model#StackFrame#scopes() dict abort
  call s:CheckType(l:self)
  let l:names = []
  for l:scope in l:self._raw_scopes
    call add(l:names, l:scope.name)
  endfor
  return l:names
endfunction

""
" @public
" @dict StackFrame
" Return a |TypeVim.Promise| that resolves to a @dict(Scope) object
" representing the DebugProtocol.Scope in this StackFrame with the requested
" {name}.
"
" @throws NotFound if this StackFrame has no DebugProtocol.Scope with {name}.
" @throws WrongType if {name} is not a string.
function! dapper#model#StackFrame#scope(name) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:name)

  let l:raw_scope = v:null
  for l:scope in l:self._raw_scopes
    if l:scope.name ==# a:name
      let l:raw_scope = l:scope
      break
    endif
  endfor
  if empty(l:raw_scope)  " no scope with the given {name}
    throw maktaba#error#NotFound('No Scope found with name: %s', a:name)
  endif

  if has_key(l:self._names_to_scopes, a:name)
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(l:self._scopes)
    return l:to_return
  else
    let l:doer = dapper#RequestDoer#New(
        \ l:self._message_passer, 'variables',
        \ {'variablesReference': l:raw_scope.variablesReference})
    let l:to_return = typevim#Promise#New(l:doer)
    return l:to_return.Then(
        \ typevim#object#Bind(
            \ l:self._HandleVariablesResponse, l:self, [l:raw_scope], 1))
  endif
endfunction

""
" @dict StackFrame
" Construct a @dict(Scope) from {msg}, a DebugProtocol.VariablesResponse,
" store it in the `_names_to_scopes` dictionary, and then return it.
"
" @throws BadValue if {scope} or {msg} are not dicts.
" @throws WrongType if {scope} is not a DebugProtocol.Scope, or {msg} is not a DebugProtocol.ProtocolMessage.
function! dapper#model#StackFrame#_HandleVariablesResponse(scope, msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:scope, dapper#dap#Scope())
  call typevim#ensure#Implements(a:msg, dapper#dap#ProtocolMessage())
  if a:msg.vim_msg_typename !=# 'VariablesResponse'
    call l:self._message_passer.NotifyReport(
        \ 'error',
        \ 'StackFrame got a non-VariablesResponse?',
        \ a:msg,
        \ l:self
        \ )
    throw maktaba#error#Failure(
        \ 'StackFrame got a non-VariablesResponse for a Scope: %s, %s',
        \ typevim#object#ShallowPrint(a:scope),
        \ typevim#object#ShallowPrint(a:msg))
  endif
  let l:new_scope =
      \ dapper#model#Scope#New(l:self._message_passer, a:scope, a:msg)
  let l:self._names_to_scopes[a:scope.name] = l:new_scope
  return l:new_scope
endfunction
