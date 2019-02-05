function! dapper#dap#ValueFormat#new() abort
  let l:new = {
    \ 'TYPE': {'ValueFormat': 1},
    \ 'hex': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ValueFormat#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ValueFormat')
  try
    let l:err = '(dapper#dap#ValueFormat) Object is not of type ValueFormat: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#ValueFormat) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
