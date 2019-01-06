" BRIEF:  Manages an 'ordinary' buffer; handles breakpoint signage and such.

" BRIEF:  Construct a SourceBuffer.
" DETAILS:  Note that SourceBuffer does *not* create a new Buffer; it is
"     expected to attach to an existing buffer.
" PARAM:  model   (dapper#model#Model)
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  bufnr   (v:t_number)
function! dapper#view#SourceBuffer#new(model, message_passer, bufnr) abort
  let l:new = dapper#view#DapperBuffer#new(a:message_passer, {'fname':''})
  let l:new['TYPE']['SourceBuffer'] = 1
  let l:new['_model'] = a:model

  let l:new['show']        = function('dapper#view#SourceBuffer#show')
  let l:new['receive']     = function('dapper#view#SourceBuffer#receive')
  let l:new['getRange']    = function('dapper#view#SourceBuffer#getRange')
  let l:new['setMappings'] = function('dapper#view#SourceBuffer#setMappings')

  let l:new['toggleBreakpoint'] =
      \ function('dapper#view#SourceBuffer#toggleBreakpoint')

  let l:new['makeEntry']   = function('dapper#view#SourceBuffer#makeEntry')

  let l:new['climbUp']     = function('dapper#view#SourceBuffer#climbUp')
  let l:new['digDown']     = function('dapper#view#SourceBuffer#digDown')
  let l:new['_makeChild']  = function('dapper#view#SourceBuffer#_makeChild')

  call a:message_passer.subscribe('StoppedEvent',
      \ function('dapper#view#SourceBuffer#receive', l:new))
  call a:message_passer.subscribe('BreakpointsResponse',
      \ function('dapper#view#SourceBuffer#receive', l:new))

  return l:new
endfunction

function! dapper#view#SourceBuffer#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SourceBuffer')
  try
    let l:err = '(dapper#view#SourceBuffer) Object is not of type SourceBuffer: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#view#SourceBuffer) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURNS:  (v:t_number)  A 'best guess' for the `bufnr` that corresponds to
"     the given source, or -1, if none could be found.
" PARAM:  source  (DebugProtocol.Source)
function! dapper#view#SourceBuffer#SourceToBufnr(source) abort
  if type(a:source) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#view#SourceBuffer) Arg not a Source:'
        \ . string(a:source)
  endif
  let l:bufnr = -1
  if has_key(a:source, 'path')
    let l:bufnr = bufnr(a:source['path'])
  endif
  if l:bufnr ==# -1
    " as fallback, just match using the name of the Source
    let l:bufnr = bufnr(a:source['path'])
  endif
  return l:bufnr
endfunction

" BRIEF:  Open the given Source.
" PARAM:  source  (DebugProtocol.Source)
function! dapper#view#SourceBuffer#show(source) abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  let l:bufnr = dapper#view#SourceBuffer#SourceToBufnr(a:source)
  if l:bufnr ==# -1
    " spawn new buffer
    let l:file = has_key(a:source, 'path') ? a:source['path'] : a:source['name']
    execute 'badd '.l:file
    let l:bufnr = bufnr(l:file)
  endif
  call l:self.setBuffer(l:bufnr)
endfunction

function! dapper#view#SourceBuffer#receive() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
endfunction

function! dapper#view#SourceBuffer#getRange() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
endfunction

function! dapper#view#SourceBuffer#setMappings() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  execute 'nnoremap <buffer> '.dapper#settings#ToggleBreakpointMapping().' '
      \ . ': call b:dapper_buffer.toggleBreakpoint()<cr>'
endfunction

function! dapper#view#SourceBuffer#makeEntry() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  " do nothing
endfunction

" BRIEF:  Set/Unset a breakpoint on the current line.
function! dapper#view#SourceBuffer#toggleBreakpoint() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  " TODO get line, send SetBreakpointsRequest
endfunction

function! dapper#view#SourceBuffer#climbUp() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  " do nothing
endfunction

function! dapper#view#SourceBuffer#digDown() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  " TODO get current Scope, open Scope in VariablesBuffer(?)
endfunction

function! dapper#view#SourceBuffer#_makeChild() abort dict
  call dapper#view#SourceBuffer#TypeCheck(l:self)
  " TODO make and return VariablesBuffer
endfunction
