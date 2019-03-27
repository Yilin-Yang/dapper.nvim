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
" @function dapper#model#VariableLookup#New({stack_frame}, {message_passer})
" Construct a VariableLookup object, used for accessing the Model
" representations of some item represented in {stack_frame}.
"
" {stack_frame} is a @dict(StackFrame). {message_passer} is an object that
" implements the @dict(MiddleTalker) interface.
"
" @throws BadValue if {stack_frame} or {message_passer} are not dicts.
" @throws WrongType if {stack_frame} is not a @dict(StackFrame), or if {message_passer} does not implement the MiddleTalker interface.
function! dapper#model#VariableLookup#New(stack_frame, message_passer) abort
  call typevim#ensure#IsType(a:stack_frame, 'StackFrame')
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:new = {
      \ '_stack_frame': a:stack_frame,
      \ '_scope_names': a:stack_frame.scopes(),
      \ '_message_passer': a:message_passer,
      \ '__names_to_scope_promises': {},
      \ 'VariableFromPath': typevim#make#Member('VariableFromPath'),
      \ }
  for l:scope in a:stack_frame.scopes()
    let l:new.__names_to_scope_promises[l:scope] = a:stack_frame.scope(l:scope)
  endfor
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""
" A |TypeVim.Doer| object that resolves with a dict between all scope names
" accessible from the current StackFrame and their corresponding @dict(Scope)
" objects.
"
" {names_to_scope_promises} is a dict between scope names and
" |TypeVim.Promise| objects that resolve to their matching @dict(Scope)s.
function! s:ScopesDoer_New(message_passer, names_to_scope_promises) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  call maktaba#ensure#IsDict(a:names_to_scope_promises)
  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_names_to_scope_promises': a:names_to_scope_promises,
      \ '_names_to_scopes': {},
      \ 'Receive': function('s:ScopesDoer_Receive'),
      \ 'StartDoing': function('s:ScopesDoer_StartDoing'),
      \ }
  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)
  call typevim#make#Derived('ScopesDoer', typevim#Doer#New(), l:new)
  return l:new
endfunction

function! s:ScopesDoer_CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, 'ScopesDoer')
endfunction

function! s:ScopesDoer_StartDoing() dict abort
  call s:ScopesDoer_CheckType(l:self)
  " request all Scope objects, directing all of them to our Receive
  " function; when all have arrived, we resolve
  for [l:___, l:promise] in items(l:self._names_to_scope_promises)
    call l:promise.Then(l:self.Receive, l:self.Reject)
  endfor
endfunction

""
" Store the given {scope}.
function! s:ScopesDoer_Receive(scope) dict abort
  call s:ScopesDoer_CheckType(l:self)
  call typevim#ensure#IsType(a:scope, 'Scope')
  let l:names_to_scopes = l:self._names_to_scopes
  let l:names_to_promises = l:self._names_to_scope_promises
  if !has_key(l:names_to_promises, a:scope.name())
    call l:self._message_passer.NotifyReport(
        \ 'warn',
        \ 'Got an unrequested Scope during VariableLookup?',
        \ a:scope,
        \ l:self)
    " throw maktaba#error#BadValue('Got an invalid Scope in ScopesDoer?')
  endif
  let l:names_to_scopes[a:scope.name()] = a:scope
  if len(l:names_to_scopes) ==# len(l:names_to_promises)
    call l:self.Resolve(l:names_to_scopes)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""
" A |TypeVim.Doer| object that recursively requests the next
" @dict(Scope)/@dict(Variable) in {lookup_path}, resolving its parent Promise
" with the last item.
"
" For details on {lookup_path}, see
" @function(dapper#model#VariableLookup#VariableFromPath).
"
" {scope_promise} is a |TypeVim.Promise| that resolves to the first
" @dict(Scope) in the path.
function! s:VariableDoer_New(message_passer, lookup_path, scope_promise) abort
  let l:new = {
      \ '_message_passer': typevim#ensure#Implements(
          \ a:message_passer, dapper#MiddleTalker#Interface()),
      \ '_lookup_path': maktaba#ensure#IsList(a:lookup_path),
      \ '_path_index': 0,
      \ '_scope_promise': typevim#ensure#IsType(a:scope_promise, 'Promise'),
      \ 'Receive': function('s:VariableDoer_Receive'),
      \ 'StartDoing': function('s:VariableDoer_StartDoing'),
      \ '_EndOfPath': function('s:VariableDoer_EndOfPath'),
      \ }
  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)
  return typevim#make#Derived('VariableDoer', typevim#Doer#New(), l:new)
endfunction

function! s:VariableDoer_CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, 'VariableDoer')
endfunction

function! s:VariableDoer_Receive(obj) dict abort
  call s:VariableDoer_CheckType(l:self)
  let l:lookup_path = l:self._lookup_path

  " make sure to increment index beforehand, since TypeVim Promises can
  " resolve instantly
  let l:idx = l:self._path_index
  let l:self._path_index += 1
  if l:idx ==# 1 && typevim#value#IsType(a:obj, 'Scope')
    let l:self._path_index -= 1  " we haven't 'really' advanced in the path
    call a:obj.variables().Then(l:self.Receive, l:self.Reject)
  elseif l:idx ==# 1  " dict between variable names and Variable objects
    call maktaba#ensure#IsDict(a:obj)
    let l:first_varname = l:lookup_path[1]
    if !has_key(a:obj, l:first_varname)
      call l:self.Reject(maktaba#error#NotFound(
          \ 'Did not find variable with name: %s', l:first_varname))
      return
    endif
    let l:first_var = a:obj[l:first_varname]
    if l:self._EndOfPath()
      call l:self.Resolve(l:first_var)
      return
    endif
    try
      call l:first_var.Child(l:lookup_path[2]).Then(
          \ l:self.Receive, l:self.Reject)
    catch /ERROR(NotFound)/
      call l:self.Reject(v:exception)
    endtry
  elseif l:idx ># 1
    call typevim#ensure#IsType(a:obj, 'Variable')
    let l:next_var = l:lookup_path[l:idx + 1]
    try
      call a:obj.Child(l:next_var).Then(l:self.Receive, l:self.Reject)
    catch /ERROR(NotFound)/
      call l:self.Reject(v:exception)
    endtry
  else  " 0 or negative index
    throw maktaba#error#Failure(
        \ 'Failed to advance path index in VariableDoer? %s',
        \ typevim#object#ShallowPrint(l:self))
  endif
endfunction

function! s:VariableDoer_StartDoing() dict abort
  call s:VariableDoer_CheckType(l:self)
  " start the lookup waterfall with the initial Scope
  let l:self._path_index += 1
  call l:self._scope_promise.Then(l:self.Receive, l:self.Reject)
endfunction

""
" Return true when the given [index] is the last element of the lookup path.
"
" @default index=the current stored path_index
function! s:VariableDoer_EndOfPath(...) dict abort
  call s:VariableDoer_CheckType(l:self)
  let l:index = maktaba#ensure#IsNumber(get(a:000, 0, l:self._path_index))
  return l:index + 1 >=# len(l:self._lookup_path)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""
" @public
" @dict VariableLookup
" Return a Promise that resolves to a @dict(Variable), or a @dict(Scope),
" corresponding to the given {lookup_path}, from the wrapped @dict(StackFrame).
"
" The {lookup_path} is hierarchical and is analogous to a filepath, with the
" very first element being the name of a scope, the next element being the
" name of a variable within that scope, the next being a member variable in
" the preceding variable, and so on. The last element in the {lookup_path} is
" the Scope/Variable to be returned.
"
" If {lookup_path} is empty, the returned Promise resolves to a dict between
" all reachable scope names and their corresponding @dict(Scope) objects.
"
" If the requested variable could not be found, the returned Promise will
" reject with the text of an ERROR(NotFound) exception.
"
" @throws NotFound if the given scope could not be found.
" @throws WrongType if {lookup_path} is not a list of strings.
function! dapper#model#VariableLookup#VariableFromPath(lookup_path) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  for l:Obj in a:lookup_path
    call maktaba#ensure#IsString(l:Obj)
  endfor

  let l:names_to_scope_promises = l:self.__names_to_scope_promises
  if empty(a:lookup_path)  " Promise resolves to all Scope objects
    let l:doer = s:ScopesDoer_New(
        \ l:self._message_passer, l:self.__names_to_scope_promises)
    return typevim#Promise#New(l:doer)
  endif

  let l:scope_name = a:lookup_path[0]
  if !has_key(l:names_to_scope_promises, l:scope_name)
    throw maktaba#error#NotFound('No Scope found with name: %s', l:scope_name)
  elseif len(a:lookup_path) ==# 1  " user requested only a Scope
    return l:names_to_scope_promises[l:scope_name]
  endif

  " user requested a variable in a scope; perform full async waterfall
  let l:scope_promise = l:names_to_scope_promises[l:scope_name]
  let l:var_doer = s:VariableDoer_New(
      \ l:self._message_passer, a:lookup_path, l:scope_promise)
  return typevim#Promise#New(l:var_doer)
endfunction
