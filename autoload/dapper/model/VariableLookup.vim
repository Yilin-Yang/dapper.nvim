let s:typename = 'VariableLookup'

""
" @dict VariableLookup
" Helper class used to asynchronously retrieve a @dict(Scope) or a particular
" @dict(Variable) from within a @dict(StackFrame); in the latter case, the
" variable might be nested deeply within other structured variables.
"
" Meant mainly for use with @dict(VariablesBuffer). Made necessary by the
" VariablesRequest "drill-down" procedure needed to retrieve children of a
" structured variable.

""
" @public
" @dict VariableLookup
" @function dapper#view#VariableLookup#New({stack_frame}, {message_passer})
" Construct a VariableLookup object, used for accessing the Model
" representations of some item represented in {stack_frame}.
"
" {stack_frame} is a @dict(StackFrame). {message_passer} is an object that
" implements the @dict(MiddleTalker) interface.
"
" @throws BadValue if {stack_frame} or {message_passer} are not dicts.
" @throws WrongType if {stack_frame} is not a @dict(StackFrame), or if {message_passer} does not implement the MiddleTalker interface.
function! dapper#view#VariableLookup#New(stack_frame, message_passer) abort
  call typevim#ensure#IsType(a:stack_frame, 'StackFrame')
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:new = {
      \ '_stack_frame': a:stack_frame,
      \ '_scope_names': a:stack_frame.scopes(),
      \ '_message_passer': a:message_passer,
      \ '__names_to_scope_promises': {},
      \ 'VariableFromPath': typevim#make#Member('VariableFromPath'),
      \ '__LookupVariablesFromScope': function('s:LookupVariablesFromScope'),
      \ '__InitiateVariableLookup': function('s:InitiateVariableLookup'),
      \ '__RecursiveLookup': function('s:RecursiveLookup'),
      \ '__ThrowNotFound': function('s:ThrowNotFound'),
      \ }
  let l:new.__LookupVariablesFromScope =
      \ typevim#object#Bind(l:new.__LookupVariablesFromScope, l:new)
  let l:new.__InitiateVariableLookup =
      \ typevim#object#Bind(l:new.__InitiateVariableLookup, l:new)
  let l:new.__RecursiveLookup =
      \ typevim#object#Bind(l:new.__RecursiveLookup, l:new)
  let l:new.__ThrowNotFound =
      \ typevim#object#Bind(l:new.__ThrowNotFound, l:new)

  for l:scope in a:stack_frame.scopes()
    let l:new.__names_to_scope_promises[l:scope] = a:stack_frame.scope(l:scope)
  endfor
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict VariableLookup
" Obtain a @dict(Variable), or a @dict(Scope), corresponding to the given
" {lookup_path}, from the wrapped @dict(StackFrame), eventually calling
" {Callback} with the resolved object.
"
" The {lookup_path} is hierarchical and is analogous to a filepath, with the
" very first element being the name of a scope, the next element being the
" name of a variable within that scope, the next being a member variable in
" the preceding variable, and so on. The last element in the {lookup_path} is
" the Scope/Variable to be returned.
"
" If {lookup_path} is empty, a dict between scope names and @dict(Scope)
" objects is returned.
"
" @throws NotFound if a scope/variable with a name given in the {lookup_path} cannot be found.
" @throws WrongType if {lookup_path} is not a list of strings, or if {Callback} is not a Funcref..
function! dapper#model#VariableLookup#VariableFromPath(
    \ lookup_path, Callback) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  for l:Obj in a:lookup_path
    call maktaba#ensure#IsString(l:Obj)
  endfor
  call maktaba#ensure#IsFuncref(a:Callback)

  function! s:AppendScopeThenCb(names, names_to_scopes, Callback, scope) abort
    call maktaba#ensure#IsList(a:names)
    call maktaba#ensure#IsDict(a:names_to_scopes)
    call maktaba#ensure#IsFuncref(a:Callback)
    call typevim#ensure#IsType(a:scope, 'Scope')
    let l:name = a:scope.name()
    " if index(a:names, l:name) ==# -1
    "   throw maktaba#error#Failure('Got wrong Scope')
    " endif
    let a:names_to_scopes[l:name] = a:scope
    if len(keys(a:names_to_scopes)) ==# len(a:names)
      call a:Callback(a:names_to_scopes)
    endif
  endfunction

  let l:names_to_scope_promises = l:self.__names_to_scope_promises
  if empty(a:lookup_path)
    let l:names_to_scopes = {}
    for l:promise in l:names_to_scope_promises
      call l:promise.Then(
          \ function(
              \ 's:AppendScopeThenCb',
              \ [l:self._stack_frame.scopes(), l:names_to_scopes, a:Callback]))
    endfor
    return
  endif

  let l:scope_name = a:lookup_path[0]
  if !has_key(l:names_to_scope_promises, l:scope_name)
    throw maktaba#error#NotFound('No Scope found with name: %s', l:scope_name)
  elseif len(a:lookup_path) ==# 1  " user requested only a Scope
    call l:names_to_scope_promises[l:scope_name].Then(a:Callback)
    return
  endif

  " user requested a variable in a scope; perform full async waterfall
  let l:scope_promise = l:names_to_scope_promises[l:scope_name]
  call l:scope_promise.Then(
      \ function(l:self.__LookupVariablesFromScope, [a:lookup_path, a:Callback]),
      \ function(l:self.__ThrowNotFound, [a:lookup_path, 0]))
endfunction

" take a Scope resolved from a StackFrame, request names-to-variables dict
function! s:LookupVariablesFromScope(lookup_path, Callback, scope) dict abort
  call maktaba#ensure#IsList(a:lookup_path)
  call maktaba#ensure#IsFuncref(a:Callback)
  call typevim#ensure#IsType(a:scope, 'Scope')
  call a:scope.variables().Then(
      \ function(l:self.__InitiateVariableLookup, [a:lookup_path, a:Callback]),
      \ function(l:self.__ThrowNotFound, [a:lookup_path, 1]))
endfunction

" take a dict between variable names and @dict(Variable) objects and use
" that to initiate a s:RecursiveLookup
function! s:InitiateVariableLookup(
    \ lookup_path, Callback, names_to_vars) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  call maktaba#ensure#IsFuncref(a:Callback)
  call maktaba#ensure#IsDict(a:names_to_vars)
  let l:root_var = a:names_to_vars[a:lookup_path[1]]
  if len(a:lookup_path) ==# 2
    call a:Callback(l:root_var)
    return
  endif
  call l:root_var.Child(a:lookup_path[2]).Then(
      \ function(l:self.__RecursiveLookup, [a:lookup_path, 3, a:Callback]),
      \ function(l:self.__ThrowNotFound,   [a:lookup_path, 3]))
endfunction

" recursively resolve Variable-Child lookup Promises
function! s:RecursiveLookup(lookup_path, idx, Callback, variable) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  call maktaba#ensure#IsNumber(a:idx)
  call maktaba#ensure#IsFuncref(a:Callback)
  call typevim#ensure#IsType(a:variable, 'Variable')
  if a:idx ==# len(a:lookup_path) - 1
    " this is the last variable in the chain
    call a:Callback(a:variable)
    return
  endif
  call a:variable.Child(a:lookup_path[a:idx + 1]).Then(
      \ function('s:RecursiveLookup', [a:lookup_path, a:idx + 1, a:Callback]),
      \ function('s:ThrowNotFound',   [a:lookup_path, a:idx + 1]))
endfunction

function! s:ThrowNotFound(lookup_path, idx, reason) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  call maktaba#ensure#IsNumber(a:idx)
  let l:varname = a:lookup_path[a:idx]
  throw maktaba#error#NotFound(
      \ 'Unable to resolve scope/varname in lookup: %s '
      \ . '(idx: %s, full-path: %s), exception: %s',
      \ l:varname, a:idx, a:lookup_path, typevim#object#ShallowPrint(a:reason))
endfunction
