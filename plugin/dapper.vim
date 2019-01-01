if exists('g:dapper_nvim_autoloaded') | finish | endif
let g:dapper_nvim_autoloaded = 1

" initialize communication interface, debug logger
let g:dapper_middletalker = dapper#MiddleTalker#get()
let g:dapper_debug_logger = dapper#log#DebugLogger#get()
  let g:dapper_report_handlers = []
  call dapper#AddDebugLogger(['status', 'error'])
