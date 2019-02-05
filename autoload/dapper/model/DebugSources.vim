" BRIEF:  Aggregate of all relevant Sources for the current debuggee.

" BRIEF:  Construct a new DebugSources object.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  capabilities    (DebugProtocol.Capabilities)
" PARAM:  Resolve (v:t_func?)
" PARAM:  Reject  (v:t_func?)
function! dapper#model#DebugSources#new(message_passer, capabilities, ...) abort
  let l:new = call('dapper#Promise#new', a:000)
  let l:new['TYPE']['DebugSources'] = 1

  let l:new['_fpaths_to_sources'] = {}
  let l:new['_message_passer'] = a:message_passer
  let l:new['_capabilities'] = a:capabilities
  let l:new['receive'] = function('dapper#model#DebugSources#receive')
  let l:new['source'] = function('dapper#model#DebugSources#source')

  let l:new['_updateSource'] = function('dapper#model#DebugSources#_updateSource')
  let l:new['_supportsLoadedSources'] =
      \ function('dapper#model#DebugSources#_supportsLoadedSources')

  if l:new._supportsLoadedSources()
    call a:message_passer.request(
        \ 'loadedSources',
        \ {},
        \ function('dapper#model#DebugSources#receive', l:new))
  endif

  call a:message_passer.subscribe(
      \ 'LoadedSourceEvent',
      \ function('dapper#model#DebugSources#receive', l:new))

  return l:new
endfunction

function! dapper#model#DebugSources#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DebugSources')
  try
    let l:err = '(dapper#model#DebugSources) Object is not of type DebugSources: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#DebugSources) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Update held Source objects from a debug adapter response.
function! dapper#model#DebugSources#receive(msg) abort dict
  call dapper#model#DebugSources#CheckType(l:self)
  let l:typename = a:msg['vim_msg_typename']
  if l:typename ==# 'LoadedSourcesResponse'
    let l:sources = a:msg['body']['sources']
    for l:updated in l:sources
      call l:self._updateSource(l:updated)
    endfor
  elseif l:typename ==# 'LoadedSourceEvent'
    " even if it's a 'removed' event
    call l:self._updateSource(a:msg['body']['source'])
    if l:self._supportsLoadedSources()
      call l:self['_message_passer'].request(
          \ 'loadedSources',
          \ {},
          \ function('dapper#model#DebugSources#receive', l:self'))
    endif
  endif
endfunction

" BRIEF:  Retrieve the Source for a filepath, creating it if it doesn't exist.
" RETURNS:  (dapper#model#Source)
" PARAM:  abs_fpath   (v:t_string)  Absolute filepath of the requested Source.
function! dapper#model#DebugSources#source(abs_fpath) abort dict
  call dapper#model#DebugSources#CheckType(l:self)
  if type(a:abs_fpath) !=# v:t_string
    throw 'ERROR(WrongType) (dapper#model#DebugSources) '
        \ . 'Given fpath not a string: ' . typevim#object#ShallowPrint(a:abs_fpath)
  endif
  let l:fpaths_to_sources = l:self['_fpaths_to_sources']
  if has_key(l:fpaths_to_sources, a:abs_fpath)
    return l:fpaths_to_sources[a:abs_fpath]
  else
    let l:new_source = dapper#model#Source#new(
        \ l:self['_message_passer'], {'path': a:abs_fpath})
    let l:fpaths_to_sources[a:abs_fpath] = l:new_source
    return l:new_source
  endif
endfunction

" BRIEF:  Update our knowledge of a particular Source.
" PARAM:  updated_source  (DebugProtocol.Source)  The updated Source; if it
"     does not contain an absolute filepath, then this function call will do
"     nothing.
function! dapper#model#DebugSources#_updateSource(updated_source) abort dict
  call dapper#model#DebugSources#CheckType(l:self)
  if type(a:updated_source) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#model#DebugSources) '
        \ . 'Given Source not a dict: '.typevim#object#ShallowPrint(a:updated_source)
  endif
  if !has_key(a:updated_source, 'path') | return | endif
  let l:current = l:self.source(a:updated_source, 'path')
  call l:current.updateFrom(a:updated_source)
endfunction

" RETURNS:  (v:t_bool)  Whether or not the current debug adapter supports the
"     `LoadedSourcesRequest`.
function! dapper#model#DebugSources#_supportsLoadedSources() abort dict
  call dapper#model#DebugSources#CheckType(l:self)
  let l:capabilities = l:self['_capabilities']
  if has_key(l:capabilities, 'supportsLoadedSourcesRequest')
    return l:capabilities['supportsLoadedSourcesRequest']
  endif
  return 0
endfunction
