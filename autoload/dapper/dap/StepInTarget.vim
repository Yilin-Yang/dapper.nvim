function! dapper#dap#StepInTarget#new() abort
  let l:new = {
    \ 'TYPE': {'StepInTarget': 1},
    \ 'id': 0,
    \ 'label': '',
  \ }
  return l:new
endfunction

function! dapper#dap#StepInTarget#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepInTarget')
    throw '(dapper#dap#StepInTarget) Object is not of type StepInTarget: ' . string(a:object)
  endif
endfunction
