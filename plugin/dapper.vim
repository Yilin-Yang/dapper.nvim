if exists('g:dapper_nvim_autoloaded') | finish | endif
let g:dapper_nvim_autoloaded = 1

" initialize communication interface
let g:dapper_middletalker = dapper#MiddleTalker#get()
