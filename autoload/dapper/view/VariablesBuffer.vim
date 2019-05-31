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
    let l:bufname = s:BufferNameFrom(l:stack_frame.name(), l:stack_frame.id())
    let l:has_stack_frame = 1
  else
    let l:bufname = s:BufferNameFrom()
  endif

  let l:base = dapper#view#DapperBuffer#new(
      \ a:message_passer, {'bufname': l:bufname})

  " TODO what if we push a new StackFrame while a variable expansion is still
  " pending?

  " DigDown and _MakeChild are noops; VariablesBuffer is a terminal node (a
  " 'leaf') in the DapperBuffer tree.
  let l:new = {
      \ '_stack_frame': l:stack_frame,
      \ '_var_lookup': v:null,
      \ '_printer': v:null,
      \ '_ResetBuffer': typevim#make#Member('_ResetBuffer'),
      \ 'stackFrame': typevim#make#Member('stackFrame'),
      \ 'Push': typevim#make#Member('Push'),
      \ 'Dump': typevim#make#Member('Dump'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'SetMappings': typevim#make#Member('SetMappings'),
      \ 'ExpandSelected': typevim#make#Member('ExpandSelected'),
      \ 'CollapseSelected': typevim#make#Member('CollapseSelected'),
      \ 'SetVariable': typevim#make#Member('SetVariable'),
      \ '_UpdateVariable': typevim#make#Member('_UpdateVariable'),
      \ 'DigDown': { -> 0},
      \ '_MakeChild': { -> 0},
      \ }
  call typevim#make#Derived(s:typename, l:base, l:new)

  let l:new._UpdateVariable = typevim#object#Bind(l:new._UpdateVariable, l:new)

  if l:has_stack_frame
    let l:new._var_lookup =
        \ dapper#model#VariableLookup#New(a:message_passer, l:stack_frame)
    let l:new._printer =
        \ dapper#view#VariablesPrinter#New(a:message_passer, l:new._var_lookup)
  endif

  call l:new._ResetBuffer()
  let s:counter += 1
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" Return a name for a VariablesBuffer, given an optional [frame_name] and
" [frame_id].
function! s:BufferNameFrom(...) abort
  let l:to_return = '[dapper.nvim] Variables'
  if a:0
    let l:to_return .= printf(' in Frame: %s,', maktaba#ensure#IsString(a:1))
  else
    let l:to_return .= ','
  endif
  if a:0 ># 1
    let l:to_return .= printf(' ID: %s,', a:2)
  endif
  let l:to_return .= printf(' (buf #%d)', s:counter)
  return typevim#string#EscapeChars(l:to_return, '#%')
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
      \ l:self._message_passer, l:self, l:self._var_lookup)

  let l:scopes = a:stack_frame.scopes()
  call l:self._ResetBuffer()
  call l:self._printer.PrintScopes(
      \ l:scopes, s:plugin.Flag('menu_expand_depth_initial'))
  call l:self.Rename(s:BufferNameFrom(a:stack_frame.name(), a:stack_frame.id()))
endfunction

""
" @public
" @dict VariablesBuffer
" Dump the contents and stored state of this VariablesBuffer.
function! dapper#view#VariablesBuffer#Dump() dict abort
  call s:CheckType(l:self)
  let l:self._stack_frame = v:null
  let l:self._var_lookup = v:null
  let l:self._printer = v:null

  call l:self._ResetBuffer()
  call l:self.Rename(s:BufferNameFrom())
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

  execute 'nnoremap <buffer> '.s:plugin.Flag('climb_up_mapping').' '
      \ . ':call b:dapper_buffer.ClimbUp()<cr>'

  execute 'nnoremap <buffer> '.s:plugin.Flag('expand_mapping').' '
      \ . ':call b:dapper_buffer.ExpandSelected()<cr>'

  execute 'nnoremap <buffer> '.s:plugin.Flag('collapse_mapping').' '
      \ . ':call b:dapper_buffer.CollapseSelected()<cr>'

  execute 'nnoremap <buffer> '.s:plugin.Flag('set_variable_mapping').' '
      \ . ':call b:dapper_buffer.SetVariable()<cr>'
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

  let l:expand_depth = s:plugin.Flag('menu_expand_depth_on_map')

  call l:var_or_scope_promise.Then(
      \ function('s:ExpandSelectedWrapper',
          \ [l:self._printer, l:lookup_path_of_selected, l:expand_depth]),
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
"
" If the currently selected @dict(Variable) is an unstructured variable, or if
" it's a structured variable that's already been collapsed, instead collapse
" its parent @dict(Scope) or @dict(Variable).
function! dapper#view#VariablesBuffer#CollapseSelected() dict abort
  call s:CheckType(l:self)
  let l:lookup_path = l:self._printer.VarFromCursor(getcurpos(), 1)

  if len(l:lookup_path) ># 1  " is variable
    " check if this is an unstructured variable
    let l:curpos = getcurpos()
    if l:curpos[1] ==# 1
      let l:curpos[1] += 1
    elseif l:curpos[1] ==# l:self.NumLines()
      let l:curpos[1] -= 1
    endif

    let l:line = l:self.GetLines(l:curpos[1])[0]
    let l:parsed_var = dapper#view#VariablesPrinter#VariableFromString(l:line)

    if !empty(l:parsed_var)
        \ && (l:parsed_var.unstructured || !l:parsed_var.expanded)
      unlet l:lookup_path[-1]  " instead, collapse the parent
    endif
  endif

  call l:self._printer.CollapseEntry(l:lookup_path)
endfunction

""
" @public
" @dict VariablesBuffer
" Request to set the value of the currently selected @dict(Variable) to the
" string [new_value]. If [new_value] is |v:null|, obtain the new value by
" prompting the user.
"
" @default new_value=|v:null|
"
" @throws WrongType if [new_value] is not a string or v:null.
function! dapper#view#VariablesBuffer#SetVariable(...) dict abort
  call s:CheckType(l:self)
  let l:new_value =
      \ maktaba#ensure#TypeMatchesOneOf(get(a:000, 0, v:null), ['', v:null])

  if !dapper#AdapterSupports('supportsSetVariable')
    call l:self._message_passer.NotifyReport(
        \ 'warn', "Debug adapter doesn't support SetVariable!",
        \ dapper#Capabilities())
    return
  endif

  let l:lookup_path = l:self._printer.VarFromCursor(getcurpos(), 1)
  let l:var_name = l:lookup_path[-1]
  if len(l:lookup_path) ==# 1
    call l:self._message_passer.NotifyReport(
        \ 'error', 'Tried to set value of a Scope: '.l:lookup_path[0])
    return
  elseif empty(l:lookup_path)
    throw maktaba#error#Failure('Could not get variable from cursor!')
  elseif len(l:lookup_path) ==# 2
    " parent is a Scope
    let l:scope_name = l:lookup_path[0]
    let l:parent_promise =
        \ l:self._var_lookup.VariableFromPath([l:scope_name])
    let l:vars_dict_promise =
        \ l:parent_promise.Then(
            \ { scope -> scope.variables() },
            \ function(l:self._printer._LogFailure, ['"set_val, get vars"']))
    let l:var_promise =
        \ l:vars_dict_promise.Then(
            \ { vars_dict -> vars_dict[l:var_name] },
            \ function(l:self._printer._LogFailure, ['"set_val, get var"']))
  else
    " order these so that, by the time var_promise resolves, parent_promise must
    " have resolved first, so that we can retrieve the parent in the child
    let l:parent_promise =
        \ l:self._var_lookup.VariableFromPath(l:lookup_path[:-2])
    let l:var_promise =
        \ l:parent_promise.Then(
            \ { parent -> parent.Child(l:var_name) },
            \ function(l:self._printer._LogFailure, ['"set_val, get par"']))
  endif

  call l:var_promise.Then(
      \ { variable ->
          \ s:SetVariableValue(l:self, l:lookup_path, l:new_value,
                             \ l:parent_promise.Get(), variable) })
      \.Catch(function(l:self._printer._LogFailure, ['"set value"']))
endfunction

""
" @private
" Invoke @function(dapper#model#Variable#SetValue). {lookup_path} is the
" lookup path of the variable. {set_val_to} is a string containing the new
" value to which the variable should be set, or |v:null| if this should be
" obtained by prompting the user. {parent} is the parent @dict(Scope) or
" @dict(Variable) of {variable}.
function! s:SetVariableValue(self, lookup_path, set_val_to, parent, variable) abort
  if a:set_val_to is v:null
    let l:prompt =
        \ printf('[dapper.nvim] Enter new value for "%s" (CTRL-C to cancel):',
                \ a:variable.name())
    let l:new_value = typevim#input(
        \ s:plugin.Flag('save_and_restore_on_input'), l:prompt,
        \ a:variable.value())
  else
    let l:new_value = a:set_val_to
  endif

  call a:variable.SetValue(a:parent.variablesReference(), l:new_value)
      \.Then(
        \ function(a:self._UpdateVariable, [a:lookup_path]))
      \.Catch(
        \ function(a:self._printer._LogFailure, ['"update from set"']))
endfunction

function! dapper#view#VariablesBuffer#_UpdateVariable(lookup_path,
                                                    \ variable) dict abort
  call s:CheckType(l:self)
  call l:self._printer.UpdateValue(a:lookup_path, a:variable)
endfunction
