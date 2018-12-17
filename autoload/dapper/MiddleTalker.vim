" BRIEF:  The interface between the VimL frontend and the TypeScript 'middle-end'.

" BRIEF:  Get the MiddleTalker singleton, or make one if it doesn't yet exist.
function! dapper#MiddleTalker#get()
  if exists('g:dapper_middletalker')
    try
      call dapper#MiddleTalker#CheckType(g:dapper_middletalker)
      " already exists
      return g:dapper_middletalker
    catch
      " invalid object, okay to overwrite
    endtry
  endif

  let g:dapper_middletalker = {
    \ 'TYPE': {'MiddleTalker': 1},
    \ 'receive': function('dapper#MiddleTalker#receive'),
  \ }

  return g:dapper_middletalker
endfunction

function! dapper#MiddleTalker#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'MiddleTalker')
    throw '(dapper#MiddleTalker) Object is not of type MiddleTalker: ' . a:object
  endif
endfunction

" BRIEF:  Receive a response or event, passing it to subscribers.
function! dapper#MiddleTalker#receive(msg) abort dict
  call dapper#MiddleTalker#CheckType(l:self)
  echo string(a:msg)
  vsp
endfunction
