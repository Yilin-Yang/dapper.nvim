" RETURNS:  (v:t_string)  The given object, dumped to a string.
function! dapper#helpers#StrDump(obj) abort
  let l:str = ''
  try
    let l:str = string(a:obj)
  catch
    redir => l:str
    silent! echo a:obj
    redir end
  endtry
  return l:str
endfunction
