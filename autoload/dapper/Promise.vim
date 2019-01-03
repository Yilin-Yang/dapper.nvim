" BRIEF:  Homebrewed Promise implementation written entirely in Vimscript.
" DETAILS:  Differs from a Java/TypeScript promise in that the returned value
"   is, essentially, the entire object.
"
"   Acts as an base class. Implementations of this class are responsible for
"   'fulfilling' or 'breaking' the Promise, generally by calling `fulfill` (on
"   Promise 'fulfillment') or `break` (on Promise 'breaking') after the
"   outcome of the Promise has been determined.
"
"   As of the time of writing, does not directly implement the automated
"   exception handling of the actual JavaScript Promise type.

" BRIEF:  Construct a Promise.
" PARAM:  Resolve (v:t_func?)   Function to be called on Promise fulfillment.
"     Shall have the following signature: `function(PromiseValue) => any`,
"     where `PromiseValue` will be the result of the Promise.
" PARAM:  Reject  (v:t_func?)   Function to be called on Promise failure.
"     Shall have the following signature: `function(ErrorObject) => any`,
"     where `ErrorObject` is some object giving information about the failure.
function! dapper#Promise#new(...) abort
  let a:Resolve = get(a:000, 0, function('dapper#Promise#__noOp'))
  if type(a:Resolve) !=# v:t_func
    throw '(dapper#Promise) Given `Resolve()` callback isn''t a funcref:'
        \ . dapper#helpers#StrDump(a:Resolve)
  endif
  let a:Reject = get(a:000, 1, function('dapper#Promise#__noOp'))
  if type(a:Reject) !=# v:t_func
    throw '(dapper#Promise) Given `Reject()` callback isn''t a funcref:'
        \ . dapper#helpers#StrDump(a:Reject)
  endif
  let l:new = {
      \ 'TYPE': {'Promise': 1},
      \ '_resolve_cbs': [a:Resolve],
      \ '_reject_cbs': [a:Reject],
      \ '_state': 'pending',
      \ '_promise_val': 0,
      \ '_error_obj': 0,
      \ 'fulfill': function('dapper#Promise#fulfill'),
      \ 'break': function('dapper#Promise#break'),
      \ 'subscribe': function('dapper#Promise#subscribe'),
      \ 'status': function('dapper#Promise#status'),
      \ }
  return l:new
endfunction

function! dapper#Promise#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Promise')
  try
    let l:err = '(dapper#Promise) Object is not of type Promise: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#Promise) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#Promise#__noImpl(funcname, ...) abort dict
  call dapper#Promise#CheckType(l:self)
  throw '(dapper#Promise) No implementation for function: '.a:funcname
endfunction

function! dapper#Promise#__noOp(...) abort
endfunction

" BRIEF:  Call back all subscribers with *this* fulfilled Promise.
function! dapper#Promise#fulfill(PromiseValue) abort dict
  call dapper#Promise#CheckType(l:self)
  let l:self['_promise_val'] = a:PromiseValue
  let l:self['_state'] = 'fulfilled'
  let l:res = l:self['_resolve_cbs']
  for l:Cb in l:res
    call l:Cb(a:PromiseValue)
  endfor
endfunction

" BRIEF:  Call back all subscribers with *this* broken Promise.
function! dapper#Promise#break(ErrorObject) abort dict
  call dapper#Promise#CheckType(l:self)
  let l:self['_error_obj'] = a:ErrorObject
  let l:self['_state'] = 'broken'
  let l:res = l:self['_reject_cbs']
  for l:Cb in l:res
    call l:Cb(a:ErrorObject)
  endfor
endfunction

" BRIEF:  Subscribe to the result of this Promise.
" PARAM:  Resolve (v:t_func)  Function to be called back when this Promise
"     resolves, possibly immediately.
" PARAM:  Reject  (v:t_func)  Function to be called back when this Promise
"     breaks, possibly immediately.
" DETAILS:  See constructor for additional details on parameters.
function! dapper#Promise#subscribe(Resolve, ...) abort dict
  if type(a:Resolve) !=# v:t_func
    throw '(dapper#Promise) Given `Resolve()` callback isn''t a funcref:'
        \ . dapper#helpers#StrDump(a:Resolve)
  endif
  let a:Reject = get(a:000, 0, function('dapper#Promise#__noOp'))
  if type(a:Reject) !=# v:t_func
    throw '(dapper#Promise) Given `Reject()` callback isn''t a funcref:'
        \ . dapper#helpers#StrDump(a:Reject)
  endif
  let l:state = l:self['_state']
  let l:res = l:self['_resolve_cbs']
  let l:rej = l:self['_reject_cbs']
  if l:state ==# 'pending'
    let l:res += [a:Resolve]
    if a:Reject !=# function('dapper#Promise#__noOp')
      let l:rej += [a:Reject]
    endif
  elseif l:state ==# 'fulfilled'
    call a:Resolve(l:self['_promise_val'])
  elseif l:state ==# 'broken'
    call a:Reject(l:self['_error_obj'])
  endif
endfunction

" RETURNS:  (v:t_string)  The status of this Promise.
function! dapper#Promise#status() abort dict
  call dapper#Promise#CheckType(l:self)
  return l:self['_state']
endfunction
