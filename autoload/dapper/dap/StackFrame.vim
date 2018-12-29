function! dapper#dap#StackFrame#new() abort
  let l:new = {
    \ 'TYPE': {'StackFrame': 1},
    \ 'id': 0,
    \ 'name': '',
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
    \ 'moduleId': 0,
    \ 'presentationHint': '',
  \ }
  return l:new
endfunction

function! dapper#dap#StackFrame#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackFrame')
    throw '(dapper#dap#StackFrame) Object is not of type StackFrame: ' . string(a:object)
  endif
endfunction
