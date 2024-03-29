if exists('g:dapper_nvim_autoloaded') | finish | endif
let g:dapper_nvim_autoloaded = 1

let g:dapper_plugin = maktaba#plugin#Get('TypeVim')

" initialize communication interface, debug logger
let g:dapper_middletalker = dapper#MiddleTalker#Get()
let g:dapper_debug_logger = dapper#log#DebugLogger#Get()
