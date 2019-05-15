""
" @section Introduction, intro
" @stylized dapper.nvim
" A neovim frontend for Microsoft's Debug Adapter Protocol, or, a concerted
" effort to take the best features of Microsoft's VSCode test editor and
" crudely staple them onto neovim.

""
" @public
" Receive a response or event from the TypeScript middle-end.
function! dapper#receive(msg) abort
  try
    call g:dapper_middletalker.Receive(a:msg)
  catch
    call g:dapper_middletalker.NotifyReport(
        \ 'error',
        \ 'Receiving message from middle-end threw exception!',
        \ 'Threw: "'.v:exception.'" from throwpoint: '.v:throwpoint,
        \ a:msg
        \ )
    throw v:exception.', from '.v:throwpoint
  endtry
endfunction

function! s:ConvertLoggerType(logger_type, funcname) abort
  let l:argtype = type(a:logger_type)
  if l:argtype !=# v:t_string && l:argtype !=# v:t_list
    throw '(dapper#'.a:funcname.') Bad argument type for arg: '.a:logger_type
  endif
  if l:argtype ==# v:t_string
    let l:types = [a:logger_type]
  else
    let l:types = a:logger_type
  endif
  return l:types
endfunction
