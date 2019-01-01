" BRIEF:  Interface for a 'level' in a hierarchy of buffers. Step up, step down.

function! dapper#RabbitHole#new(message_passer, bufname, ...) abort
  let l:new = call(
      \ 'dapper#DapperBuffer#new',
      \ [a:message_passer, {'fname': a:bufname}] + a:000)
  let l:new['TYPE']['RabbitHole'] = 1
  let l:new['climbUp'] = function('dapper#RabbitHole#__noImpl', ['climbUp'])
  let l:new['digDown'] = function('dapper#RabbitHole#__noImpl', ['digDown'])
  " set self as a buffer-local variable, accessible by switching
  " to/opening this buffer
  call setbufvar(l:new.bufnr(), 'dapper_buffer', l:new)
  return l:new
endfunction

function! dapper#RabbitHole#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'RabbitHole')
  try
    let l:err = '(dapper#RabbitHole) Object is not of type RabbitHole: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#RabbitHole) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#RabbitHole#__noImpl(func_name, ...) abort dict
  call dapper#RabbitHole#CheckType(l:self)
  throw '(dapper#RabbitHole) Invoked pure virtual function: '.a:func_name
endfunction

