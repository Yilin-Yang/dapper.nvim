function! dapper#dap#Breakpoint#new() abort
  let l:new = {
    \ 'TYPE': {'Breakpoint': 1},
    \ 'id': 0,
    \ 'verified': v:false,
    \ 'message': '',
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#Breakpoint#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Breakpoint')
  try
    let l:err = '(dapper#dap#Breakpoint) Object is not of type Breakpoint: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#Breakpoint) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
