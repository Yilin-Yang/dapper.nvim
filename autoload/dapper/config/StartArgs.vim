function! dapper#dap#StartArgs() abort
  let l:new = {
    \ 'TYPE': {'StartArgs': 1},
    \ 'runtime_env': '',
    \ 'exe_filepath': '',
    \ 'adapter_id': '',
    \ 'locale': '',
  \ }
  return l:new
endfunction
