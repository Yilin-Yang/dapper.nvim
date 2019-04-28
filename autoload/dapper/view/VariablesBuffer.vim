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

  " TODO what if we push a new StackFrame while a variable expansion is still
  " pending?

  " DigDown and _MakeChild are noops; VariablesBuffer is a terminal node (a
  " 'leaf') in the DapperBuffer tree.
  let l:new = {
      \ '_stack_frame': l:stack_frame,
      \ '_names_to_scopes': {},
      \ '_lookup': v:null,
      \ '_printer': v:null,
      \ '_ResetBuffer': typevim#make#Member('_ResetBuffer'),
      \ 'stackFrame': typevim#make#Member('stackFrame'),
      \ 'Push': typevim#make#Member('Push'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'SetMappings': typevim#make#Member('SetMappings'),
      \ 'ExpandSelected': typevim#make#Member('ExpandSelected'),
      \ 'CollapseSelected': typevim#make#Member('CollapseSelected'),
      \ 'DigDown': { -> 0},
      \ '_MakeChild': { -> 0},
      \ }
  call typevim#make#Derived(s:typename, l:base, l:new)

  if l:has_stack_frame
    let l:new._lookup =
        \ dapper#model#VariableLookup#New(a:message_passer, l:stack_frame)
    let l:new._printer =
        \ dapper#view#VariablesPrinter#New(a:message_passer, l:new._lookup)
  endif

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
" {stack_frame}. The buffer will update when the given @dict(StackFrame)
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
  let l:self._printer = dapper#view#VariablesPrinter#New(
      \ l:self._message_passer, l:self._var_lookup)

  let l:self._names_to_scopes = {}
  let l:scopes = a:stack_frame.scopes()

  " TODO configurable default recursion depth
  call l:self._printer.PrintScopes(l:scopes)
endfunction

""
" @public
" @dict VariablesBuffer
" See @function(dapper#view#VariablesPrinter#GetRange).
function! dapper#view#VariablesBuffer#GetRange(lookup_path_of_var) dict abort
  call s:CheckType(l:self)
  call l:self._printer.GetRange(a:lookup_path_of_var)
endfunction

function! dapper#view#VariablesBuffer#SetMappings() dict abort
  call s:CheckType(l:self)
  call setbufvar(l:self.bufnr(), 'dapper_buffer', l:self)
  execute 'nnoremap <buffer> '.s:plugin.flags.climb_up_mapping.Get().' '
      \ . ':call b:dapper_buffer.ClimbUp()<cr>'

  " TODO separate mapping for 'expand variable' that defauls to the same as
  " DigDown?
  execute 'nnoremap <buffer> '.s:plugin.flags.dig_down_mapping.Get().' '
      \ . ':call b:dapper_buffer.ExpandSelected()<cr>'
endfunction

""
" @public
" @dict VariablesBuffer
" Expand (or merely update) the currently selected @dict(Scope) or
" @dict(Variable) inside the current buffer.
function! dapper#view#VariablesBuffer#ExpandSelected() dict abort
  call s:CheckType(l:self)
  let l:lookup_path_of_selected = l:self._printer.VarFromCursor(getcurpos(), 1)
  let l:var_or_scope_promise =
      \ l:self._var_lookup.VariableFromPath(l:lookup_path_of_selected)

  " TODO configurable 'expansion depth'?
  call l:var_or_scope_promise.Then(
      \ function('s:ExpandSelectedWrapper',
          \ [l:self._printer, l:lookup_path_of_selected, 1]),
      \ function(l:self._printer._LogFailure, ['"expand selected"']))
endfunction

function! s:ExpandSelectedWrapper(printer, path, rec_depth, var_or_scope) abort
  call a:printer.ExpandEntry(a:path, a:var_or_scope, a:rec_depth)
endfunction

""
" @public
" @dict VariablesBuffer
" Collapse the currently selected @dict(Scope) or @dict(Variable) inside the
" current buffer.
function! dapper#view#VariablesBuffer#CollapseSelected() dict abort
  call s:CheckType(l:self)
  call l:self._printer.CollapseEntry(
      \ l:self._printer.VarFromCursor(getcurpos(), 1))
endfunction
