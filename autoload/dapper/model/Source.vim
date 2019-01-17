" BRIEF:  Represent a Source.

" BRIEF:  Construct a new Source object.
" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  initial_source  (DebugProtocol.Source)
function! dapper#model#Source#new(message_passer, initial_source) abort
  " let l:new = call('dapper#Promise#new', a:000)
  let l:new = {}
  let l:new['TYPE']['Source'] = 1

  let l:new['_message_passer'] = a:message_ppasser
  let l:new['_props'] = dapper#dap#Source#new()
  let l:new['_bps'] =
      \ dapper#model#SourceBreakpoints#new(a:message_passer, a:initial_source)

  let l:new['bps'] = function('dapper#model#Source#bps')
  let l:new['updateFrom'] = function('dapper#model#Source#updateFrom')

  call l:new.updateFrom(a:initial_source)

  return l:new
endfunction

function! dapper#model#Source#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Source')
  try
    let l:err = '(dapper#model#Source) Object is not of type Source: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#Source) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Update the 'known properties' of this Source object.
function! dapper#model#Source#updateFrom(source) abort dict
  call dapper#model#Source#CheckType(l:self)
  if type(a:source) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#model#Source) '
        \ . 'Given source properties aren''t a dict: '
        \ . dapper#helpers#StrDump(a:source)
  endif
  call extend(l:self['_props'], a:source, 'force')
endfunction

" RETURNS:  (dapper#model#SourceBreakpoints)
function! dapper#model#Source#bps() abort dict
  call dapper#model#Source#CheckType(l:self)
  return l:self['_bps']
endfunction
