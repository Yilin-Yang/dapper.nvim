" PARAM:  vim_id  (v:t_number?)
" PARAM:  vim_msg_typename  (v:t_string?)
" PARAM:  kind  (v:t_string?)
" PARAM:  brief (v:t_string?)
" PARAM:  long  (v:t_string?)
" PARAM:  alert (v:t_bool?)
" PARAM:  other (any?)
function! dapper#dap#Report#new(...)
  let l:new = call('dapper#dap#ProtocolMessage#new', a:000)
  let a:vim_msg_typename = get(a:000, 1, '')
  let a:kind  = get(a:000, 2, '')
  let a:brief = get(a:000, 3, '')
  let a:long  = get(a:000, 4, '')
  let a:alert = get(a:000, 5, v:false)
  let a:other = get(a:000, 6, '')

  let l:new['type']  = 'report'
  let l:new['kind']  = a:kind
  let l:new['brief'] = a:brief
  let l:new['long']  = a:long
  let l:new['alert'] = a:alert
  let l:new['other'] = a:other

  if a:kind !=# '' && a:vim_msg_typename ==# ''
    let l:new['vim_msg_typename'] = toupper(a:kind[0:0]).a:kind[1:].'Report'
  endif

  return l:new
endfunction

function! dapper#dap#Report#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Report')
  try
    let l:err = '(dapper#dap#Report) Object is not of type Report: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#Report) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
