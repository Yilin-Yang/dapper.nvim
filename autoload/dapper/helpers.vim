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

" RETURNS:  (v:t_list) List of all files and folders at the given directory
"     path. Filenames and foldernames are given as strings.
function! dapper#helpers#ls(dir_path) abort
  if type(a:dir_path) !=# v:t_string
    throw 'ERROR(WrongType) dirname must be given as string: '
        \ . dapper#helpers#StrDump(a:dir_path)
  endif
  let l:raw_ls = ''
  redir => l:raw_ls
    silent! echo system(dapper#settings#lsCommand().shellescape(a:dir_path))
  redir end
  if v:shell_error
    throw 'ERROR(Failure) Failed to list files in given directory: '.a:dir_path
  endif
  let l:contents = split(l:raw_ls, '[\n\r]', v:false)
  if empty(l:contents[-1]) | unlet l:contents[-1] | endif
  return l:contents
endfunction
