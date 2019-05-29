let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

" initialize communication interface, debug logger
let g:dapper_middletalker = dapper#MiddleTalker#Get()
let g:dapper_debug_logger = dapper#log#DebugLogger#Get()
