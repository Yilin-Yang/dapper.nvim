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

""
" @public
" Return the value of {setting_name}, a scoped variable (e.g.
" `"g:dapper_foobar"`, including the leading `"g:"`), or {default}, if
" {setting_name} has no value set.
"
" This function exists so that dapper.nvim may present a familiar, "legacy"
" interface for plugin settings to the end user, should they decide not to use
" glaive.
"
" [type], if not equal to -1, is the type that the setting represented by
" {setting_name} should possess. If equal to -1, the function will compare
" the setting's type against that of {default}.
"
" @default type=-1
" @throws WrongType if [type] is -1 and the variable that {setting_name} represents does not have the same type as {default}; or if [type] is not -1 and the setting's type does not match it.
" @throws Failure if {setting_name} is malformed.
function! dapper#GlobalVarOrDefault(setting_name, Default, ...)
  call maktaba#ensure#IsString(a:setting_name)
  if a:0 && a:1 !=# -1
    if !typevim#value#IsTypeConstant(a:1)
      throw maktaba#error#WrongType(
          \ 'Did''nt give a type constant when setting value for %s!',
          \ a:setting_name)
    endif
    let l:type = a:1
  else
    let l:type = -1
  endif
  if exists(a:setting_name)
    execute 'let l:SetVal = '.a:setting_name
  else
    let l:SetVal = a:Default
  endif
  if l:type ==# -1
    if !maktaba#value#TypeMatches(l:SetVal, a:Default)
      call s:ThrowBadSettingType(
          \ a:setting_name, type(l:SetVal), type(a:Default))
    endif
  elseif l:type ==# typevim#Any()
    " perform no type checking
  else
    if type(l:SetVal) !=# l:type
        \ && !(l:type ==# typevim#Bool() && typevim#value#IsBool(l:SetVal))
      call s:ThrowBadSettingType(a:setting_name, type(l:SetVal), l:type)
    endif
  endif
  return l:SetVal
endfunction

function! s:ThrowBadSettingType(setting_name, actual_const, expected_const) abort
  throw maktaba#error#WrongType(
      \ 'Bad type for setting %s. Expected %s, got a %s.',
      \ a:setting_name,
      \ typevim#value#ConstantToTypeName(a:expected_const),
      \ typevim#value#ConstantToTypeName(a:actual_const))
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
