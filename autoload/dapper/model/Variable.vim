""
" @dict Variable
" Represent the contents of a variable.

let s:plugin = maktaba#plugin#Get('dapper.nvim')
let s:typename = 'Variable'

""
" @public
" @function dapper#model#Variable#New({message_passer}, {variable})
" Construct a Variable object from a {message_passer} and a {variable}.
"
" @throws BadValue if {message_passer} or {variable} are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if {variable} is not a DebugProtocol.Variable.
function! dapper#model#Variable#New(message_passer, variable) abort
  return dapper#model#Variable#__New(a:message_passer, a:variable, 0)
endfunction

let s:FUNC_PREFIX = 'dapper#model#Variable#'
let s:PROTOTYPE = {
    \ 'name': function(s:FUNC_PREFIX.'name'),
    \ 'value': function(s:FUNC_PREFIX.'value'),
    \ 'type': function(s:FUNC_PREFIX.'type'),
    \ 'presentationHint': function(s:FUNC_PREFIX.'presentationHint'),
    \ 'evaluateName': function(s:FUNC_PREFIX.'evaluateName'),
    \ 'variablesReference': function(s:FUNC_PREFIX.'variablesReference'),
    \ 'namedVariables': function(s:FUNC_PREFIX.'namedVariables'),
    \ 'indexedVariables': function(s:FUNC_PREFIX.'indexedVariables'),
    \
    \ '_UpdateFromMsg': function(s:FUNC_PREFIX.'_UpdateFromMsg'),
    \ '_HandleFailedReq': function(s:FUNC_PREFIX.'_HandleFailedReq'),
    \ 'HasChildren': function(s:FUNC_PREFIX.'HasChildren'),
    \ 'ChildNames': function(s:FUNC_PREFIX.'ChildNames'),
    \ 'Children': function(s:FUNC_PREFIX.'Children'),
    \ 'Child': function(s:FUNC_PREFIX.'Child'),
    \ }
call typevim#make#Class(s:typename, s:PROTOTYPE)

function! dapper#model#Variable#__New(message_passer, variable, recursion_depth) abort
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  call typevim#ensure#Implements(a:variable, dapper#dap#Variable())
  call maktaba#ensure#IsNumber(a:recursion_depth)

  let l:new = deepcopy(s:PROTOTYPE)
  call extend(l:new, {
      \ '_message_passer': a:message_passer,
      \ '_variable': a:variable,
      \ '_names_to_children': {},
      \ '__recursion_depth': a:recursion_depth,
      \ })

  let l:new._UpdateFromMsg = typevim#object#Bind(l:new._UpdateFromMsg, l:new)
  let l:new._HandleFailedReq =
      \ typevim#object#Bind(l:new._HandleFailedReq, l:new)

  " immediately start populating variable entries
  " TODO cache this 'constructor Promise', have async functions resolve when
  " it does (to eliminate redundant VariablesRequests while this request is
  " pending)
  call dapper#model#Variable#__GetPromiseAutopopulate(l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" Return {property} of {self}, if present. Else, return |v:null|.
function! s:ReturnPropIfPresent(self, property) abort
  call s:CheckType(a:self)
  call maktaba#ensure#IsString(a:property)
  if has_key(a:self._variable, a:property)
    return a:self._variable[a:property]
  endif
  return v:null
endfunction

""
" @public
" @dict Variable
" Return the name of this variable, or |v:null| if it could not be found.
function! dapper#model#Variable#name() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'name')
endfunction

""
" @public
" @dict Variable
" Return the value of this variable, as a single string, or |v:null| if it
" could not be found.
function! dapper#model#Variable#value() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'value')
endfunction

""
" @public
" @dict Variable
" Return the type of this variable, or |v:null| if it could not be found.
function! dapper#model#Variable#type() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'type')
endfunction

""
" @public
" @dict Variable
" Return a hint as to how this variable should be presented in the UI, or
" |v:null| if it could not be found.
function! dapper#model#Variable#presentationHint() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'presentationHint')
endfunction

""
" @public
" @dict Variable
" Return an expression representing this Variable that is usable in a
" DebugProtocol.EvaluateRequest, or |v:null| if it could not be found.
function! dapper#model#Variable#evaluateName() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'evaluateName')
endfunction

""
" @public
" @dict Variable
" Return the "variablesReference" identifier of this variable, or |v:null| if
" it could not be found. A nonzero return value indicates that this is a
" "structured" Variable with child variables, and that the return value is
" usable in a VariablesRequest.
function! dapper#model#Variable#variablesReference() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'variablesReference')
endfunction

""
" @public
" @dict Variable
" Return the number of named child variables held by this variable, if it is a
" "structured" variable, or |v:null| if it could not be found.
function! dapper#model#Variable#namedVariables() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'namedVariables')
endfunction

""
" @public
" @dict Variable
" Return the number of indexed child variables held by this variable, if it is
" a "structured" variable, or |v:null| if it could not be found.
function! dapper#model#Variable#indexedVariables() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'indexedVariables')
endfunction

""
" @dict Variable
" Update the child variables of this Variable from a newly received
" DebugProtocol.VariablesResponse. Return the newly constructed Variable
" children.
"
" @throws BadValue if {msg} is not a dict.
" @throws WrongType if {msg} is not a @dict(ProtocolMessage).
function! dapper#model#Variable#_UpdateFromMsg(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#ProtocolMessage())
  if !empty(l:self._names_to_children)
    " call l:self._message_passer.NotifyReport(
    "     \ 'error',
    "     \ 'Variable obj updated, but didn''t clear children?',
    "     \ a:msg,
    "     \ l:self
    "     \ )
    let l:self._names_to_children = {}
  endif
  if a:msg.vim_msg_typename !=# 'VariablesResponse'
    let l:name = l:self.name()
    call l:self._message_passer.NotifyReport(
        \ 'error',
        \ 'Variable '.l:name.' got a non-VariablesResponse!',
        \ a:msg,
        \ l:self
        \ )
    throw maktaba#error#Failure(
        \ 'Variable %s got a non-VariablesResponse!', l:name)
  endif
  for l:raw_var in a:msg.body.variables
    let l:new_var = dapper#model#Variable#__New(
        \ l:self._message_passer, l:raw_var, l:self.__recursion_depth + 1)
    let l:self._names_to_children[l:new_var.name()] = l:new_var
  endfor
  return copy(l:self._names_to_children)
endfunction

""
" @dict Variable
" Log the outright failure of a VariablesRequest.
function! dapper#model#Variable#_HandleFailedReq(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#ProtocolMessage())
  let l:name = l:self.name()
  call l:self._message_passer.NotifyReport(
      \ 'error',
      \ 'Attempt to populate variable '.l:name.' failed!',
      \ a:msg,
      \ l:self
      \ )
  let l:self._names_to_children = {}
  return {}
endfunction

""
" @public
" @dict Variable
" Return true if this is a "structured" Variable with children, and false
" otherwise.
function! dapper#model#Variable#HasChildren() dict abort
  call s:CheckType(l:self)
  return l:self.variablesReference() !=# 0
endfunction

""
" @public
" @dict Variable
" Return a |TypeVim.Promise| that resolves with a list of the names of all
" named variable children of this variable, if any.
function! dapper#model#Variable#ChildNames() dict abort
  call s:CheckType(l:self)
  if empty(l:self._names_to_children)
    " updates with new _names_to_children, and resolves with same dict;
    " only the former is needed for __ReturnChildNames
    let l:to_return = dapper#model#Variable#__GetPromiseUpdateChild()
    return l:to_return.Then(
        \ typevim#object#Bind(
            \ function('dapper#model#Variable#__ReturnChildNames'), [l:self]))
  else
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(
        \ dapper#model#Variable#__ReturnChildNames(l:self, v:null))
    return l:to_return
  endif
endfunction

""
" @public
" @dict Variable
" Return a |TypeVim.Promise| that resolves to a dict between names/indices of
" variables, and the child variables themselves.
function! dapper#model#Variable#Children() dict abort
  call s:CheckType(l:self)
  if empty(l:self._names_to_children)
    return dapper#model#Variable#__GetPromiseUpdateChild(l:self)
  else
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(copy(l:self._names_to_children))
    return l:to_return
  endif
endfunction

""
" @public
" @dict Variable
" Return a |TypeVim.Promise| that resolves to the child Variable having the
" given {name_or_idx}.
"
" @throws NotFound if no child variable with the given {name_or_idx} could be found.
" @throws WrongType if {name_or_idx} is not a string.
function! dapper#model#Variable#Child(name_or_idx) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:name_or_idx)
  if empty(l:self._names_to_children)
    let l:children_promise =
        \ dapper#model#Variable#__GetPromiseUpdateChild(l:self)
    return l:children_promise.Then(
        \ function('dapper#model#Variable#__ReturnChildWithName',
            \ [l:self, a:name_or_idx]))
  else
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve(
        \ dapper#model#Variable#__ReturnChildWithName(l:self, a:name_or_idx))
    return l:to_return
  endif
endfunction

""
" @dict Variable
" Return the child Variable in {self} having name {name_or_idx}, or throw an
" ERROR(NotFound).
function! dapper#model#Variable#__ReturnChildWithName(self, name_or_idx, ...) abort
  call s:CheckType(a:self)
  call maktaba#ensure#IsString(a:name_or_idx)
  if !has_key(a:self._names_to_children, a:name_or_idx)
    throw maktaba#error#NotFound(
        \ 'No child variable found in %s with name/idx: %s',
        \ a:self.name(), a:name_or_idx)
  endif
  return a:self._names_to_children[a:name_or_idx]
endfunction

""
" @dict Variable
" The same as @function(dapper#model#Variable#__GetPromiseUpdateChild), but
" meant to be invoked exclusively from the Variable constructor. Halts and
" does nothing if the recursion depth has gone too deep.
function! dapper#model#Variable#__GetPromiseAutopopulate(self) abort
  call s:CheckType(a:self)
  if a:self.__recursion_depth ># s:plugin.Flag('max_drilldown_recursion')
    call a:self._message_passer.NotifyReport(
        \ 'debug',
        \ 'Too deeply nested, halting drill-down: '.a:self.name()
        \ )
    return
  endif
  call dapper#model#Variable#__GetPromiseUpdateChild(a:self)
endfunction

""
" @dict Variable
" Return a |TypeVim.Promise| that, after updating the "_names_to_children"
" dict of this object, resolves to that same dictionary.
function! dapper#model#Variable#__GetPromiseUpdateChild(self) abort
  call s:CheckType(a:self)

  function! s:ReturnEmpty()
    let l:to_return = typevim#Promise#New()
    call l:to_return.Resolve({})
    return l:to_return
  endfunction

  try
    let l:var_ref = a:self.variablesReference()
    if !l:var_ref | return s:ReturnEmpty() | endif
  catch ERROR(NotFound)
    return s:ReturnEmpty()
  endtry
  let a:self._names_to_children = {}
  let l:doer = dapper#RequestDoer#New(
      \ a:self._message_passer, 'variables',
      \ {'variablesReference': l:var_ref})
  let l:to_return = typevim#Promise#New(l:doer)
  return l:to_return.Then(a:self._UpdateFromMsg, a:self._HandleFailedReq)
endfunction

""
" @dict Variable
" Return a list of the names of all named children of the given Variable
" {self}.
function! dapper#model#Variable#__ReturnChildNames(self, ___) abort
  call s:CheckType(a:self)
  let l:names = []
  for [l:name, l:var] in items(a:self._names_to_children)
    call add(l:names, l:name)
  endfor
  return l:names
endfunction
