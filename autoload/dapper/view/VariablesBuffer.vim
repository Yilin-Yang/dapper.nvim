""
" @dict VariablesBuffer
" Shows variables accessible from the current stack frame, organized by their
" parent scope.

let s:plugin = maktaba#plugin#Get('dapper.nvim')

let s:typename = 'VariablesBuffer'
let s:counter = 0

""
" @public
" @dict VariablesBuffer
" @function dapper#view#VariablesBuffer#New({message_passer}, [stack_frame])
" Construct a VariablesBuffer from a {message_passer} and, optionally, the
" @dict(StackFrame) object that the VariablesBuffer should show.
"
" @default {stack_frame}={}
"
" @throws BadValue if {message_passer} or {stack_frame} are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if [stack_frame] is nonempty and is not a @dict(StackFrame).
function! dapper#view#VariablesBuffer#New(message_passer, ...) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:stack_frame = get(a:000, 0, {})
  if !empty(l:stack_frame)
    call typevim#ensure#IsType(l:stack_frame, 'StackFrame')
  endif

  let l:base = dapper#view#DapperBuffer#new(
          \ a:message_passer,
          \ {'bufname': '[dapper.nvim] Variables, '.s:counter})

  let l:new = {
      \ '_stack_frame': l:stack_frame,
      \ '_names_to_scopes': {},
      \ '_ResetBuffer': typevim#make#Member('_ResetBuffer'),
      \ 'stackFrame': typevim#make#Member('stackFrame'),
      \ 'Push': typevim#make#Member('Push'),
      \ '_PrintFailedResponse': typevim#make#Member('_PrintFailedResponse'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'SetMappings': typevim#make#Member('SetMappings'),
      \ 'ClimbUp': typevim#make#Member('ClimbUp'),
      \ 'DigDown': typevim#make#Member('DigDown'),
      \ '_MakeChild': typevim#make#Member('_MakeChild'),
      \ '_GetSelected': typevim#make#Member('_GetSelected'),
      \ '_ShowVariables': typevim#make#Member('_ShowVariables'),
      \ }
  call typevim#make#Derived(s:typename, l:base, l:new)
  let l:new._PrintFailedResponse =
      \ typevim#object#Bind(l:new._PrintFailedResponse, l:new)
  let l:new._ShowVariables =
      \ typevim#object#Bind(l:new._ShowVariables, l:new)
  call l:new._ResetBuffer()
  return l:new
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:linemanip = 'LineManipulator'

""
" Construct a new LineManipulator object, used for manipulating the contents
" of a VariablesBuffer.
"
" {model_lookup} is a ModelLookup object.
function! s:LineManipNew(model_lookup) abort
  call s:CheckModelLookup(a:model_lookup)
  let l:new = {
      \ '_model_lookup': a:model_lookup,
      \ 'PrintVariable': function('s:PrintVariable'),
      \ 'GetRange': function('s:GetRange'),
      \ 'GetSelected': function('s:GetSelected'),
      \ 'ExpandEntry': function('s:ExpandEntry'),
      \ 'CollapseEntry': function('s:CollapseEntry'),
      \ }
  return typevim#make#Class(s:linemanip, l:new)
endfunction

function! s:CheckLineManip(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:linemanip)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:modellookup = 'ModelLookup'

""
" Construct a ModelLookup object, used for accessing the Model representations
" of some item represented in this VariablesBuffer.
"
" {names_to_scopes} is a dictionary from scope names (e.g. "Local") to the
" corresponding @dict(Scope) object.
"
" {message_passer} is an object that implements the @dict(MiddleTalker)
" interface.
function! dapper#view#VariablesBuffer#NewModelLookup(
    \ names_to_scopes, message_passer) abort
  call maktaba#ensure#IsDict(a:names_to_scopes)
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:new = {
      \ '_names_to_scopes': a:names_to_scopes,
      \ '_message_passer': a:message_passer,
      \ 'VariableFromPath': function('s:VariableFromPath'),
      \ }
  return typevim#make#Class(s:modellookup, l:new)
endfunction

function! s:CheckModelLookup(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:modellookup)
endfunction

""
" Obtain a @dict(Variable), or a @dict(Scope), corresponding to the given
" {lookup_path}, using it to invoke {Callback} once obtained.
"
" The {lookup_path} is hierarchical and is analogous to a filepath, with the
" very first element being the name of a scope, the next element being the
" name of a variable within that scope, the next being a member variable in
" the preceding variable, and so on. The last element in the {lookup_path} is
" the Scope/Variable to be returned.
"
" If {lookup_path} is empty, the full "_names_to_scopes" dict is returned.
"
" @throws NotFound if a scope/variable with a name given in the {lookup_path} cannot be found.
" @throws WrongType if {lookup_path} is not a list of strings, or if {Callback} is not a Funcref..
function! s:VariableFromPath(lookup_path, Callback) dict abort
  call s:CheckModelLookup(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  for l:Obj in a:lookup_path
    call maktaba#ensure#IsString(l:Obj)
  endfor
  call maktaba#ensure#IsFuncref(a:Callback)
  let l:names_to_scopes = l:self._names_to_scopes
  if empty(a:lookup_path)
    call a:Callback(l:names_to_scopes)
    return
  endif
  let l:scope = a:lookup_path[0]
  if !has_key(l:names_to_scopes, l:scope)
    throw maktaba#error#NotFound('No Scope found with name: %s', l:scope)
  elseif len(a:lookup_path) ==# 1
    call a:Callback(l:names_to_scopes[l:scope])
    return
  endif

  " TODO
  let l:scope = l:names_to_scopes[l:scope]
  call l:scope.variables().Then(
      \ function('s:InitiateVariableLookup', [a:lookup_path, a:Callback]),
        \ function('s:ThrowNotFound', [a:lookup_path, 1]))

  " take a dict between variable names and @dict(Variable) objects and use
  " that to initiate a s:RecursiveLookup
  function! s:InitiateVariableLookup(lookup_path, Callback, names_to_vars) abort
    call maktaba#ensure#IsList(a:lookup_path)
    call maktaba#ensure#IsFuncref(a:Callback)
    call maktaba#ensure#IsDict(a:names_to_vars)
    let l:root_var = a:names_to_vars[a:lookup_path[1]]
    if len(a:lookup_path) ==# 2
      call a:Callback(l:root_var)
      return
    endif
    call l:root_var.Child(a:lookup_path[2]).Then(
        \ function('s:RecursiveLookup', [a:lookup_path, 3, a:Callback]),
        \ function('s:ThrowNotFound',   [a:lookup_path, 3]))
  endfunction

  " recursively resolve Variable-Child lookup Promises
  function! s:RecursiveLookup(lookup_path, idx, Callback, variable) abort
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

  function! s:ThrowNotFound(lookup_path, idx) abort
    call maktaba#ensure#IsList(a:lookup_path)
    call maktaba#ensure#IsNumber(a:idx)
    let l:varname = a:lookup_path[a:idx]
    throw maktaba#error#NotFound(
        \ 'Unable to resolve scope/varname in lookup: %s '
        \ . '(idx: %s, full-path: %s)', l:varname, a:idx, a:lookup_path)
  endfunction
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict VariablesBuffer
" Clear the contents of this buffer, leaving only a pair of opening and
" closing `"<variables>"` tags.
function! dapper#view#VariablesBuffer#_ResetBuffer() dict abort
  call s:CheckType(l:self)
  call l:self.ReplaceLines(1, -1, ['<variables>', '</variables>'])
endfunction

""
" @public
" @dict VariablesBuffer
" Return the stack frame object whose scopes and variables this buffer shows.
function! dapper#view#StackTraceBuffer#stackFrame() dict abort
  call s:CheckType(l:self)
  return l:self._stack_frame
endfunction

""
" @public
" @dict VariablesBuffer
" Display the scopes (and the variables) accessible from the given
" {stack_frame}. The buffer will update when the given @dict(StackFrame) is
" receives DebugProtocol.VariablesResponse updates from the debug adapter, or
" throw an appropriate error message if the request fails entirely.
"
" @throws BadValue if {stack_frame} is not a dict.
" @throws WrongType if {stack_frame} is not a @dict(StackFrame).
function! dapper#view#VariablesBuffer#Push(stack_frame) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:stack_frame, 'Thread')
  let l:self._stack_frame = a:stack_frame
  " TODO mark existing Scopes as obsolete until they're replaced?
  let l:self._names_to_scopes = {}
  let l:scopes = a:stack_frame.scopes()
  for l:scope in l:scopes
    let l:scope_promise = a:stack_frame.scope(l:scope)
    call l:scope_promise.Then(
        \ l:self._ShowVariables,
        \ l:self._PrintFailedResponse)
    call l:self._Log(
        \ 'debug',
        \ 'Will print VariablesResponse(s) in this buffer',
        \ l:scope_promise,
        \ l:self
        \ )
  endfor
endfunction

""
" @dict VariablesBuffer
" Display the given {scope}, and its variables, in the buffer. Scopes will be
" sorted in alphabetical order by their name.
"
" @throws BadValue if {scope} is not a dict.
" @throws WrongType if {scope} is not a @dict(Scope).
function! dapper#view#VariablesBuffer#_ShowVariables(scope) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#IsType(a:scope, 'Scope')
  " TODO
  " retrieve the line range of the given Scope
  " if it exists, replace it; if it doesn't, insert it at the appropriate
  " position
endfunction
