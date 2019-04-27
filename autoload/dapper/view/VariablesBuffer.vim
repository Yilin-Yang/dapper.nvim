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
" @default stack_frame={}
"
" @throws BadValue if {message_passer} or [stack_frame] are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if [stack_frame] is nonempty and is not a @dict(StackFrame).
function! dapper#view#VariablesBuffer#New(message_passer, ...) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  let l:stack_frame = get(a:000, 0, {})
  let l:has_stack_frame = 0
  if !empty(l:stack_frame)
    call typevim#ensure#IsType(l:stack_frame, 'StackFrame')
    let l:has_stack_frame = 1
  endif

  let l:base = dapper#view#DapperBuffer#new(
          \ a:message_passer,
          \ {'bufname': '[dapper.nvim] Variables, '.s:counter})

  let l:new = {
      \ '_stack_frame': l:stack_frame,
      \ '_names_to_scopes': {},
      \ '_lookup': v:null,
      \ '_printer': v:null,
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

  if l:has_stack_frame
    let l:new._lookup =
        \ dapper#model#VariableLookup#New(a:message_passer, l:stack_frame)
    let l:new._printer =
        \ dapper#view#VariablesPrinter#New(a:message_passer, l:new._lookup)
  endif

  let l:new._PrintFailedResponse =
      \ typevim#object#Bind(l:new._PrintFailedResponse, l:new)
  let l:new._ShowVariables =
      \ typevim#object#Bind(l:new._ShowVariables, l:new)
  call l:new._ResetBuffer()
  return l:new
endfunction

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
function! dapper#view#VariablesBuffer#stackFrame() dict abort
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
  let l:self._stack_frame = typevim#ensure#IsType(a:stack_frame, 'StackFrame')
  let l:self._var_lookup =
      \ dapper#model#VariableLookup#New(l:self._message_passer, a:stack_frame)
  let l:self._printer =
      \ dapper#view#VariablesPrinter#New(l:self._message_passer, )
  " TODO replace member variables using new stack frame
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
