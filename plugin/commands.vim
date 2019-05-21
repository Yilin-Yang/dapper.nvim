let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Opens dapper.nvim's debug log buffer in the current window.
command! -nargs=0 DapperLog   call g:dapper_debug_logger.buffer.Open()
