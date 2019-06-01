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
" @function dapper#model#VariableLookup#Interface()
" @dict VariableLookup
" Returns the interface that VariableLookup implements.
function! dapper#model#VariableLookup#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'VariableFromPath': typevim#Func(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction

""
" @public
" @dict VariableLookup
" @function dapper#model#VariableLookup#New({message_passer}, {stack_frame})
" Construct a VariableLookup object, used for accessing the Model
" representations of some item represented in {stack_frame}.
"
" {stack_frame} is a @dict(StackFrame). {message_passer} is an object that
" implements the @dict(MiddleTalker) interface.
"
" @throws BadValue if {stack_frame} or {message_passer} are not dicts.
" @throws WrongType if {stack_frame} is not a @dict(StackFrame), or if {message_passer} does not implement the MiddleTalker interface.
function! dapper#model#VariableLookup#New(message_passer, stack_frame) abort
  call typevim#ensure#IsType(a:stack_frame, 'StackFrame')
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:new = {
      \ '_stack_frame': a:stack_frame,
      \ '_scope_names': a:stack_frame.scopes(),
      \ '_message_passer': a:message_passer,
      \ '__names_to_scope_promises': s:ScopePromisesFromFrame(a:stack_frame),
      \ 'VariableFromPath': typevim#make#Member('VariableFromPath'),
      \ 'Update': typevim#make#Member('Update'),
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

function! s:ScopePromisesFromFrame(stack_frame) abort
  let l:names_to_promises = {}
  for l:scope in a:stack_frame.scopes()
    let l:names_to_promises[l:scope] = a:stack_frame.scope(l:scope)
  endfor
  return l:names_to_promises
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
      \ '_scope_promise': typevim#ensure#IsType(a:scope_promise, 'Promise'),
      \ 'Receive': function('s:VariableDoer_Receive'),
      \ 'StartDoing': function('s:VariableDoer_StartDoing'),
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

  if typevim#value#IsType(a:obj, 'Scope')
    " this is a Scope object; request a dict of its variables
    call a:obj.variables().Then(l:self.Receive, l:self.Reject)
  elseif maktaba#value#IsDict(a:obj) && !typevim#value#IsValidObject(a:obj)
    " dict between variable names and Variable objects
    let l:first_varname = l:lookup_path[0]
    unlet l:lookup_path[0]  " pop
    if !has_key(a:obj, l:first_varname)
      call l:self.Reject(maktaba#error#NotFound(
          \ 'Did not find variable with name: %s', l:first_varname))
      return
    endif
    let l:first_var = a:obj[l:first_varname]
    if empty(l:lookup_path)
      call l:self.Resolve(l:first_var)
      return
    endif
    let l:varname_of_firsts_child = l:lookup_path[0]
    unlet l:lookup_path[0]
    call l:first_var.Child(l:varname_of_firsts_child).Then(
        \ l:self.Receive, l:self.Reject)
  elseif typevim#value#IsType(a:obj, 'Variable')
    if empty(l:lookup_path)
      call l:self.Resolve(a:obj)
      return
    endif
    let l:next_var = l:lookup_path[0]
    unlet l:lookup_path[0]
    call a:obj.Child(l:next_var).Then(l:self.Receive, l:self.Reject)
  else
    throw maktaba#error#Failure(
        \ 'Received unexpected object in VariableDoer_Receive: ',
        \ typevim#object#ShallowPrint(l:self))
  endif
endfunction

function! s:VariableDoer_StartDoing() dict abort
  call s:VariableDoer_CheckType(l:self)
  " start the lookup waterfall with the initial Scope
  unlet l:self._lookup_path[0]  " 'pop' front of list
  call l:self._scope_promise.Then(l:self.Receive, l:self.Reject)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:EnsureCopyIsListOfStrings(Obj) abort
  let l:copy = copy(maktaba#ensure#IsList(a:Obj))
  for l:Obj in l:copy
    call maktaba#ensure#IsString(l:Obj)
  endfor
  return l:copy
endfunction

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
" @throws NotFound if the given scope or variable could not be found.
" @throws WrongType if {lookup_path} is not a list of strings.
function! dapper#model#VariableLookup#VariableFromPath(lookup_path) dict abort
  call s:CheckType(l:self)
  " copy lookup_path to avoid unexpectedly modifying the lookup_path
  " that the user had provided
  let l:lookup_path = s:EnsureCopyIsListOfStrings(a:lookup_path)

  let l:names_to_scope_promises = l:self.__names_to_scope_promises
  if empty(l:lookup_path)  " Promise resolves to all Scope objects
    let l:doer = s:ScopesDoer_New(
        \ l:self._message_passer, l:self.__names_to_scope_promises)
    return typevim#Promise#New(l:doer)
  endif

  let l:scope_name = l:lookup_path[0]
  if !has_key(l:names_to_scope_promises, l:scope_name)
    throw maktaba#error#NotFound('No Scope found with name: %s', l:scope_name)
  elseif len(l:lookup_path) ==# 1  " user requested only a Scope
    return l:names_to_scope_promises[l:scope_name]
  endif

  " user requested a variable in a scope; perform full async waterfall
  let l:scope_promise = l:names_to_scope_promises[l:scope_name]
  let l:var_doer = s:VariableDoer_New(
      \ l:self._message_passer, l:lookup_path, l:scope_promise)
  return typevim#Promise#New(l:var_doer)
endfunction

""
" @public
" @dict VariableLookup
" Forcibly repopulate the @dict(Scope) or @dict(Variable) denoted by
" {lookup_path}. Return a |TypeVim.Promise| that resolves to the updated Scope
" or Variable.
"
" If {lookup_path} is empty, all Scopes are repopulated and the returned
" Promise resolves to a dict between all reachable scope names and their
" corresponding @dict(Scope) objects.
"
" @throws NotFound if the requested scope or variable could not be found.
" @throws WrongType if {lookup_path} is not a list of strings.
function! dapper#model#VariableLookup#Refresh(lookup_path) dict abort
  call s:CheckType(l:self)
  let l:lookup_path = s:EnsureCopyIsListOfStrings(a:lookup_path)
  let l:stack_frame = l:self._stack_frame
  if empty(l:lookup_path)
    call l:stack_frame.ClearCache()
    let l:self.__names_to_scope_promises =
        \ s:ScopePromisesFromFrame(l:self._stack_frame)
    return l:self.VariableFromPath([])
  endif

  let l:scope_name = l:lookup_path[0]
  let l:names_to_scope_promises = l:self.__names_to_scope_promises
  if !has_key(l:names_to_scope_promises, l:scope_name)
    throw maktaba#error#NotFound('No Scope found with name: %s', l:scope_name)
  elseif len(l:lookup_path) ==# 1  " refresh a Scope
    call l:stack_frame.ClearCache(l:lookup_path[0])
    let l:scope_promise = l:stack_frame.scope(l:scope_name)
    let l:names_to_scope_promises[l:scope_name] = l:scope_promise
    return l:scope_promise
  else
    " drill down to the parent of the requested variable and refresh it
    let l:parent = l:self.VariableFromPath(a:lookup_path[-2])
    let l:to_refresh = a:lookup_path[-1]
    if l:parent.State() ==# 'fulfilled'
      " if the Promise isn't already fulfilled, then there's nothing to refresh
      return l:parent
    endif
    if len(l:lookup_path) ==# 2  " refresh a Variable inside a Scope
      return l:parent.Then({ scope -> scope.Refresh(l:to_refresh) })
    else  " refresh a Variable inside of a Variable
      return l:parent.Then({ var -> var.Refresh(l:to_refresh) })
    endif
  endif
endfunction
