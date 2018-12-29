function! dapper#dap#ValueFormat#new() abort
  let l:new = {
    \ 'TYPE': {'ValueFormat': 1},
    \ 'hex': v:false,
  \ }
  return l:new
endfunction

function! dapper#dap#ValueFormat#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ValueFormat')
    throw '(dapper#dap#ValueFormat) Object is not of type ValueFormat: ' . string(a:object)
  endif
endfunction
