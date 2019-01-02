" BRIEF:  Interface for a 'level' in a hierarchy of buffers. Step up, step down.

" PARAM:  message_passer  (dapper#MiddleTalker)
" PARAM:  bufname         (v:t_string)
function! dapper#view#RabbitHole#new(message_passer, bufname) abort
  let l:new = call(
      \ 'dapper#view#DapperBuffer#new',
      \ [a:message_passer, {'fname': a:bufname}])
  let l:new['TYPE']['RabbitHole'] = 1
  let l:new['climbUp'] = function('dapper#view#RabbitHole#__noImpl', ['climbUp'])
  let l:new['digDown'] = function('dapper#view#RabbitHole#__noImpl', ['digDown'])
  " set self as a buffer-local variable, accessible by switching
  " to/opening this buffer
  call setbufvar(l:new.bufnr(), 'dapper_buffer', l:new)
  return l:new
endfunction

function! dapper#view#RabbitHole#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'RabbitHole')
  try
    let l:err = '(dapper#view#RabbitHole) Object is not of type RabbitHole: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#view#RabbitHole) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#view#RabbitHole#__noImpl(func_name, ...) abort dict
  call dapper#view#RabbitHole#CheckType(l:self)
  throw '(dapper#view#RabbitHole) Invoked pure virtual function: '.a:func_name
endfunction

