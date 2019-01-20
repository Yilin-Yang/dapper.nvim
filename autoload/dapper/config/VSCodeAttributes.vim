" BRIEF:  Attributes from a `launch.json` that are VSCode-specific.
function! dapper#config#VSCodeAttributes#new() abort
  let l:new = {
      \ 'TYPE': {'VSCodeAttributes': 1},
      \ 'preLaunchTask': '',
      \ 'postLaunchTask': '',
      \ 'internalConsoleOptions': '',
      \ 'debugServer': '',
      \ }
  return l:new
endfunction

function! dapper#config#VSCodeAttributes#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'VSCodeAttributes')
  try
    let l:err = '(dapper#config#VSCodeAttributes) Object is not of type VSCodeAttributes: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#config#VSCodeAttributes) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
