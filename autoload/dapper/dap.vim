let s:MsgTypenameToInterface = {}

""
" @private
" @dict DapperMessage
" A dictionary, annotated with a human-readable (and @dict(MiddleTalker)-parsable)
" typename, and possibly the ID of a frontend object.
function! dapper#dap#DapperMessage() abort
  let l:vim_msg_typename = 'DapperMessage'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'vim_msg_typename': typevim#String(),
      \ 'vim_id': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction

function! dapper#dap#ProtocolMessage() abort
  let l:vim_msg_typename = 'ProtocolMessage'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'seq': typevim#Number(),
      \ 'type': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction

function! dapper#dap#Request() abort
  let l:vim_msg_typename = 'Request'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'type': ['request'],
      \ 'command': typevim#String(),
      \ 'arguments?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#ProtocolMessage(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Event() abort
  let l:vim_msg_typename = 'Event'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'type': ['event'],
      \ 'event': typevim#String(),
      \ 'body?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#ProtocolMessage(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Response() abort
  let l:vim_msg_typename = 'Response'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'type': ['response'],
      \ 'request_seq': typevim#Number(),
      \ 'success': typevim#Bool(),
      \ 'command': typevim#String(),
      \ 'message?': typevim#String(),
      \ 'body?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#ProtocolMessage(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Response() abort
  let l:vim_msg_typename = 'Response'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'type': ['report'],
      \ 'kind': typevim#String(),
      \ 'brief': typevim#String(),
      \ 'long': typevim#String(),
      \ 'alert': typevim#Bool(),
      \ 'other?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#ProtocolMessage(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ErrorResponse() abort
  let l:vim_msg_typename = 'ErrorResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'error?': dapper#dap#Message(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#InitializedEvent() abort
  let l:vim_msg_typename = 'InitializedEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StoppedEvent() abort
  let l:vim_msg_typename = 'StoppedEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'reason': typevim#String(),
        \ 'description?': typevim#String(),
        \ 'threadId?': typevim#Number(),
        \ 'preserveFocusHint?': typevim#Bool(),
        \ 'text?': typevim#String(),
        \ 'allThreadsStopped?': typevim#Bool(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ContinuedEvent() abort
  let l:vim_msg_typename = 'ContinuedEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'threadId': typevim#Number(),
        \ 'allThreadsContinued?': typevim#Bool(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExitedEvent() abort
  let l:vim_msg_typename = 'ExitedEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'exitCode': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminatedEvent() abort
  let l:vim_msg_typename = 'TerminatedEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body?': {
        \ 'restart?': typevim#Any(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ThreadEvent() abort
  let l:vim_msg_typename = 'ThreadEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'reason': typevim#String(),
        \ 'threadId': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#OutputEvent() abort
  let l:vim_msg_typename = 'OutputEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'category?': typevim#String(),
        \ 'output': typevim#String(),
        \ 'variablesReference?': typevim#Number(),
        \ 'source?': dapper#dap#Source(),
        \ 'line?': typevim#Number(),
        \ 'column?': typevim#Number(),
        \ 'data?': typevim#Any(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#BreakpointEvent() abort
  let l:vim_msg_typename = 'BreakpointEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'reason': typevim#String(),
        \ 'breakpoint': dapper#dap#Breakpoint(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ModuleEvent() abort
  let l:vim_msg_typename = 'ModuleEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'reason': ['new', 'changed', 'removed'],
        \ 'module': dapper#dap#Module(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LoadedSourceEvent() abort
  let l:vim_msg_typename = 'LoadedSourceEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'reason': ['new', 'changed', 'removed'],
        \ 'source': dapper#dap#Source(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ProcessEvent() abort
  let l:vim_msg_typename = 'ProcessEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'name': typevim#String(),
        \ 'systemProcessId?': typevim#Number(),
        \ 'isLocalProcess?': typevim#Bool(),
        \ 'startMethod?': ['launch', 'attach', 'attachForSuspendedLaunch'],
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#CapabilitiesEvent() abort
  let l:vim_msg_typename = 'CapabilitiesEvent'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'capabilities': dapper#dap#Capabilities(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Event(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RunInTerminalRequest() abort
  let l:vim_msg_typename = 'RunInTerminalRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#RunInTerminalRequestArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction

function! dapper#dap#RunInTerminalRequestArguments() abort
  let l:vim_msg_typename = 'RunInTerminalRequestArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'kind?': ['integrated', 'external'],
      \ 'title?': typevim#String(),
      \ 'cwd': typevim#String(),
      \ 'args': typevim#List(),
      \ 'env?': typevim#Dict(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RunInTerminalResponse() abort
  let l:vim_msg_typename = 'RunInTerminalResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'processId?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#InitializeRequest() abort
  let l:vim_msg_typename = 'InitializeRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#InitializeRequestArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#InitializeRequestArguments() abort
  let l:vim_msg_typename = 'InitializeRequestArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'clientID?': typevim#String(),
      \ 'clientName?': typevim#String(),
      \ 'adapterID': typevim#String(),
      \ 'locale?': typevim#String(),
      \ 'linesStartAt1?': typevim#Bool(),
      \ 'columnsStartAt1?': typevim#Bool(),
      \ 'pathFormat?': typevim#String(),
      \ 'supportsVariableType?': typevim#Bool(),
      \ 'supportsVariablePaging?': typevim#Bool(),
      \ 'supportsRunInTerminalRequest?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#InitializeResponse() abort
  let l:vim_msg_typename = 'InitializeResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body?': dapper#dap#Capabilities(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ConfigurationDoneRequest() abort
  let l:vim_msg_typename = 'ConfigurationDoneRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments?': dapper#dap#ConfigurationDoneArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ConfigurationDoneArguments() abort
  let l:vim_msg_typename = 'ConfigurationDoneArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ConfigurationDoneResponse() abort
  let l:vim_msg_typename = 'ConfigurationDoneResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LaunchRequest() abort
  let l:vim_msg_typename = 'LaunchRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#LaunchRequestArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LaunchRequestArguments() abort
  let l:vim_msg_typename = 'LaunchRequestArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'noDebug?': typevim#Bool(),
      \ '__restart?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LaunchResponse() abort
  let l:vim_msg_typename = 'LaunchResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#AttachRequest() abort
  let l:vim_msg_typename = 'AttachRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#AttachRequestArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#AttachRequestArguments() abort
  let l:vim_msg_typename = 'AttachRequestArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ '__restart?': typevim#Any(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#AttachResponse() abort
  let l:vim_msg_typename = 'AttachResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartRequest() abort
  let l:vim_msg_typename = 'RestartRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments?': dapper#dap#RestartArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartArguments() abort
  let l:vim_msg_typename = 'RestartArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartResponse() abort
  let l:vim_msg_typename = 'RestartResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#DisconnectRequest() abort
  let l:vim_msg_typename = 'DisconnectRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments?': dapper#dap#DisconnectArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#DisconnectArguments() abort
  let l:vim_msg_typename = 'DisconnectArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'restart?': typevim#Bool(),
      \ 'terminateDebuggee?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#DisconnectResponse() abort
  let l:vim_msg_typename = 'DisconnectResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateRequest() abort
  let l:vim_msg_typename = 'TerminateRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments?': dapper#dap#TerminateArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateArguments() abort
  let l:vim_msg_typename = 'TerminateArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'restart?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateResponse() abort
  let l:vim_msg_typename = 'TerminateResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetBreakpointsRequest() abort
  let l:vim_msg_typename = 'SetBreakpointsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SetBreakpointsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetBreakpointsArguments() abort
  let l:vim_msg_typename = 'SetBreakpointsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'source': dapper#dap#Source(),
      \ 'breakpoints?': typevim#List(),
      \ 'lines?': typevim#List(),
      \ 'sourceModified?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetBreakpointsResponse() abort
  let l:vim_msg_typename = 'SetBreakpointsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'breakpoints': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetFunctionBreakpointsRequest() abort
  let l:vim_msg_typename = 'SetFunctionBreakpointsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SetFunctionBreakpointsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetFunctionBreakpointsArguments() abort
  let l:vim_msg_typename = 'SetFunctionBreakpointsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'breakpoints': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetFunctionBreakpointsResponse() abort
  let l:vim_msg_typename = 'SetFunctionBreakpointsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'breakpoints': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExceptionBreakpointsRequest() abort
  let l:vim_msg_typename = 'SetExceptionBreakpointsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SetExceptionBreakpointsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExceptionBreakpointsArguments() abort
  let l:vim_msg_typename = 'SetExceptionBreakpointsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'filters': typevim#List(),
      \ 'exceptionOptions?': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExceptionBreakpointsResponse() abort
  let l:vim_msg_typename = 'SetExceptionBreakpointsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ContinueRequest() abort
  let l:vim_msg_typename = 'ContinueRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#ContinueArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ContinueArguments() abort
  let l:vim_msg_typename = 'ContinueArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ContinueResponse() abort
  let l:vim_msg_typename = 'ContinueResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'allThreadsContinued?': typevim#Bool(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#NextRequest() abort
  let l:vim_msg_typename = 'NextRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#NextArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#NextArguments() abort
  let l:vim_msg_typename = 'NextArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#NextResponse() abort
  let l:vim_msg_typename = 'NextResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInRequest() abort
  let l:vim_msg_typename = 'StepInRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#StepInArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInArguments() abort
  let l:vim_msg_typename = 'StepInArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ 'targetId?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInResponse() abort
  let l:vim_msg_typename = 'StepInResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepOutRequest() abort
  let l:vim_msg_typename = 'StepOutRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#StepOutArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepOutArguments() abort
  let l:vim_msg_typename = 'StepOutArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepOutResponse() abort
  let l:vim_msg_typename = 'StepOutResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepBackRequest() abort
  let l:vim_msg_typename = 'StepBackRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#StepBackArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepBackArguments() abort
  let l:vim_msg_typename = 'StepBackArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepBackResponse() abort
  let l:vim_msg_typename = 'StepBackResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ReverseContinueRequest() abort
  let l:vim_msg_typename = 'ReverseContinueRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#ReverseContinueArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ReverseContinueArguments() abort
  let l:vim_msg_typename = 'ReverseContinueArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ReverseContinueResponse() abort
  let l:vim_msg_typename = 'ReverseContinueResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartFrameRequest() abort
  let l:vim_msg_typename = 'RestartFrameRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#RestartFrameArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartFrameArguments() abort
  let l:vim_msg_typename = 'RestartFrameArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'frameId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#RestartFrameResponse() abort
  let l:vim_msg_typename = 'RestartFrameResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoRequest() abort
  let l:vim_msg_typename = 'GotoRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#GotoArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoArguments() abort
  let l:vim_msg_typename = 'GotoArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ 'targetId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoResponse() abort
  let l:vim_msg_typename = 'GotoResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#PauseRequest() abort
  let l:vim_msg_typename = 'PauseRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#PauseArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#PauseArguments() abort
  let l:vim_msg_typename = 'PauseArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#PauseResponse() abort
  let l:vim_msg_typename = 'PauseResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StackTraceRequest() abort
  let l:vim_msg_typename = 'StackTraceRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#StackTraceArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StackTraceArguments() abort
  let l:vim_msg_typename = 'StackTraceArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ 'startFrame?': typevim#Number(),
      \ 'levels?': typevim#Number(),
      \ 'format?': dapper#dap#StackFrameFormat(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StackTraceResponse() abort
  let l:vim_msg_typename = 'StackTraceResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'stackFrames': typevim#List(),
        \ 'totalFrames?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ScopesRequest() abort
  let l:vim_msg_typename = 'ScopesRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#ScopesArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ScopesArguments() abort
  let l:vim_msg_typename = 'ScopesArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'frameId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ScopesResponse() abort
  let l:vim_msg_typename = 'ScopesResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'scopes': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#VariablesRequest() abort
  let l:vim_msg_typename = 'VariablesRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#VariablesArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#VariablesArguments() abort
  let l:vim_msg_typename = 'VariablesArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'variablesReference': typevim#Number(),
      \ 'filter?': ['indexed', 'named'],
      \ 'start?': typevim#Number(),
      \ 'count?': typevim#Number(),
      \ 'format?': dapper#dap#ValueFormat(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#VariablesResponse() abort
  let l:vim_msg_typename = 'VariablesResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'variables': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetVariableRequest() abort
  let l:vim_msg_typename = 'SetVariableRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SetVariableArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetVariableArguments() abort
  let l:vim_msg_typename = 'SetVariableArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'variablesReference': typevim#Number(),
      \ 'name': typevim#String(),
      \ 'value': typevim#String(),
      \ 'format?': dapper#dap#ValueFormat(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetVariableResponse() abort
  let l:vim_msg_typename = 'SetVariableResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'value': typevim#String(),
        \ 'type?': typevim#String(),
        \ 'variablesReference?': typevim#Number(),
        \ 'namedVariables?': typevim#Number(),
        \ 'indexedVariables?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SourceRequest() abort
  let l:vim_msg_typename = 'SourceRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SourceArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SourceArguments() abort
  let l:vim_msg_typename = 'SourceArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'source?': dapper#dap#Source(),
      \ 'sourceReference': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SourceResponse() abort
  let l:vim_msg_typename = 'SourceResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'content': typevim#String(),
        \ 'mimeType?': typevim#String(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ThreadsRequest() abort
  let l:vim_msg_typename = 'ThreadsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ThreadsResponse() abort
  let l:vim_msg_typename = 'ThreadsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'threads': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateThreadsRequest() abort
  let l:vim_msg_typename = 'TerminateThreadsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#TerminateThreadsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateThreadsArguments() abort
  let l:vim_msg_typename = 'TerminateThreadsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadIds?': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#TerminateThreadsResponse() abort
  let l:vim_msg_typename = 'TerminateThreadsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ModulesRequest() abort
  let l:vim_msg_typename = 'ModulesRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#ModulesArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ModulesArguments() abort
  let l:vim_msg_typename = 'ModulesArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'startModule?': typevim#Number(),
      \ 'moduleCount?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ModulesResponse() abort
  let l:vim_msg_typename = 'ModulesResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'modules': typevim#List(),
        \ 'totalModules?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LoadedSourcesRequest() abort
  let l:vim_msg_typename = 'LoadedSourcesRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments?': dapper#dap#LoadedSourcesArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LoadedSourcesArguments() abort
  let l:vim_msg_typename = 'LoadedSourcesArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, {})
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#LoadedSourcesResponse() abort
  let l:vim_msg_typename = 'LoadedSourcesResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'sources': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#EvaluateRequest() abort
  let l:vim_msg_typename = 'EvaluateRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#EvaluateArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#EvaluateArguments() abort
  let l:vim_msg_typename = 'EvaluateArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'expression': typevim#String(),
      \ 'frameId?': typevim#Number(),
      \ 'context?': typevim#String(),
      \ 'format?': dapper#dap#ValueFormat(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#EvaluateResponse() abort
  let l:vim_msg_typename = 'EvaluateResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'result': typevim#String(),
        \ 'type?': typevim#String(),
        \ 'presentationHint?': dapper#dap#VariablePresentationHint(),
        \ 'variablesReference': typevim#Number(),
        \ 'namedVariables?': typevim#Number(),
        \ 'indexedVariables?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExpressionRequest() abort
  let l:vim_msg_typename = 'SetExpressionRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#SetExpressionArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExpressionArguments() abort
  let l:vim_msg_typename = 'SetExpressionArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'expression': typevim#String(),
      \ 'value': typevim#String(),
      \ 'frameId?': typevim#Number(),
      \ 'format?': dapper#dap#ValueFormat(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SetExpressionResponse() abort
  let l:vim_msg_typename = 'SetExpressionResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'value': typevim#String(),
        \ 'type?': typevim#String(),
        \ 'presentationHint?': dapper#dap#VariablePresentationHint(),
        \ 'variablesReference?': typevim#Number(),
        \ 'namedVariables?': typevim#Number(),
        \ 'indexedVariables?': typevim#Number(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInTargetsRequest() abort
  let l:vim_msg_typename = 'StepInTargetsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#StepInTargetsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInTargetsArguments() abort
  let l:vim_msg_typename = 'StepInTargetsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'frameId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInTargetsResponse() abort
  let l:vim_msg_typename = 'StepInTargetsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'targets': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoTargetsRequest() abort
  let l:vim_msg_typename = 'GotoTargetsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#GotoTargetsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoTargetsArguments() abort
  let l:vim_msg_typename = 'GotoTargetsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'source': dapper#dap#Source(),
      \ 'line': typevim#Number(),
      \ 'column?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoTargetsResponse() abort
  let l:vim_msg_typename = 'GotoTargetsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'targets': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#CompletionsRequest() abort
  let l:vim_msg_typename = 'CompletionsRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#CompletionsArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#CompletionsArguments() abort
  let l:vim_msg_typename = 'CompletionsArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'frameId?': typevim#Number(),
      \ 'text': typevim#String(),
      \ 'column': typevim#Number(),
      \ 'line?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#CompletionsResponse() abort
  let l:vim_msg_typename = 'CompletionsResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'targets': typevim#List(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionInfoRequest() abort
  let l:vim_msg_typename = 'ExceptionInfoRequest'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'arguments': dapper#dap#ExceptionInfoArguments(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Request(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionInfoArguments() abort
  let l:vim_msg_typename = 'ExceptionInfoArguments'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'threadId': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionInfoResponse() abort
  let l:vim_msg_typename = 'ExceptionInfoResponse'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'body': {
        \ 'exceptionId': typevim#String(),
        \ 'description?': typevim#String(),
        \ 'breakMode': dapper#dap#ExceptionBreakMode(),
        \ 'details?': dapper#dap#ExceptionDetails(),
        \ },
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#Response(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Capabilities() abort
  let l:vim_msg_typename = 'Capabilities'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'supportsConfigurationDoneRequest?': typevim#Bool(),
      \ 'supportsFunctionBreakpoints?': typevim#Bool(),
      \ 'supportsConditionalBreakpoints?': typevim#Bool(),
      \ 'supportsHitConditionalBreakpoints?': typevim#Bool(),
      \ 'supportsEvaluateForHovers?': typevim#Bool(),
      \ 'exceptionBreakpointFilters?': typevim#List(),
      \ 'supportsStepBack?': typevim#Bool(),
      \ 'supportsSetVariable?': typevim#Bool(),
      \ 'supportsRestartFrame?': typevim#Bool(),
      \ 'supportsGotoTargetsRequest?': typevim#Bool(),
      \ 'supportsStepInTargetsRequest?': typevim#Bool(),
      \ 'supportsCompletionsRequest?': typevim#Bool(),
      \ 'supportsModulesRequest?': typevim#Bool(),
      \ 'additionalModuleColumns?': typevim#List(),
      \ 'supportedChecksumAlgorithms?': typevim#List(),
      \ 'supportsRestartRequest?': typevim#Bool(),
      \ 'supportsExceptionOptions?': typevim#Bool(),
      \ 'supportsValueFormattingOptions?': typevim#Bool(),
      \ 'supportsExceptionInfoRequest?': typevim#Bool(),
      \ 'supportTerminateDebuggee?': typevim#Bool(),
      \ 'supportsDelayedStackTraceLoading?': typevim#Bool(),
      \ 'supportsLoadedSourcesRequest?': typevim#Bool(),
      \ 'supportsLogPoints?': typevim#Bool(),
      \ 'supportsTerminateThreadsRequest?': typevim#Bool(),
      \ 'supportsSetExpression?': typevim#Bool(),
      \ 'supportsTerminateRequest?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionBreakpointsFilter() abort
  let l:vim_msg_typename = 'ExceptionBreakpointsFilter'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'filter': typevim#String(),
      \ 'label': typevim#String(),
      \ 'default?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Message() abort
  let l:vim_msg_typename = 'Message'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': typevim#Number(),
      \ 'format': typevim#String(),
      \ 'variables?': typevim#Dict(),
      \ 'sendTelemetry?': typevim#Bool(),
      \ 'showUser?': typevim#Bool(),
      \ 'url?': typevim#String(),
      \ 'urlLabel?': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Module() abort
  let l:vim_msg_typename = 'Module'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': [typevim#Number(), typevim#String()],
      \ 'name': typevim#String(),
      \ 'path?': typevim#String(),
      \ 'isOptimized?': typevim#Bool(),
      \ 'isUserCode?': typevim#Bool(),
      \ 'version?': typevim#String(),
      \ 'symbolStatus?': typevim#String(),
      \ 'symbolFilePath?': typevim#String(),
      \ 'dateTimeStamp?': typevim#String(),
      \ 'addressRange?': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ColumnDescriptor() abort
  let l:vim_msg_typename = 'ColumnDescriptor'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'attributeName': typevim#String(),
      \ 'label': typevim#String(),
      \ 'format?': typevim#String(),
      \ 'type?': ['string', 'number', 'boolean', 'unixTimestampUTC'],
      \ 'width?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ModulesViewDescriptor() abort
  let l:vim_msg_typename = 'ModulesViewDescriptor'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'columns': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Thread() abort
  let l:vim_msg_typename = 'Thread'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': typevim#Number(),
      \ 'name': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Source() abort
  let l:vim_msg_typename = 'Source'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'name?': typevim#String(),
      \ 'path?': typevim#String(),
      \ 'sourceReference?': typevim#Number(),
      \ 'presentationHint?': ['normal', 'emphasize', 'deemphasize'],
      \ 'origin?': typevim#String(),
      \ 'sources?': typevim#List(),
      \ 'adapterData?': typevim#Any(),
      \ 'checksums?': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StackFrame() abort
  let l:vim_msg_typename = 'StackFrame'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': typevim#Number(),
      \ 'name': typevim#String(),
      \ 'source?': dapper#dap#Source(),
      \ 'line': typevim#Number(),
      \ 'column': typevim#Number(),
      \ 'endLine?': typevim#Number(),
      \ 'endColumn?': typevim#Number(),
      \ 'moduleId?': [typevim#Number(), typevim#String()],
      \ 'presentationHint?': ['normal', 'label', 'subtle'],
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Scope() abort
  let l:vim_msg_typename = 'Scope'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'name': typevim#String(),
      \ 'variablesReference': typevim#Number(),
      \ 'namedVariables?': typevim#Number(),
      \ 'indexedVariables?': typevim#Number(),
      \ 'expensive': typevim#Bool(),
      \ 'source?': dapper#dap#Source(),
      \ 'line?': typevim#Number(),
      \ 'column?': typevim#Number(),
      \ 'endLine?': typevim#Number(),
      \ 'endColumn?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Variable() abort
  let l:vim_msg_typename = 'Variable'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'name': typevim#String(),
      \ 'value': typevim#String(),
      \ 'type?': typevim#String(),
      \ 'presentationHint?': dapper#dap#VariablePresentationHint(),
      \ 'evaluateName?': typevim#String(),
      \ 'variablesReference': typevim#Number(),
      \ 'namedVariables?': typevim#Number(),
      \ 'indexedVariables?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#VariablePresentationHint() abort
  let l:vim_msg_typename = 'VariablePresentationHint'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'kind?': typevim#String(),
      \ 'attributes?': typevim#List(),
      \ 'visibility?': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#SourceBreakpoint() abort
  let l:vim_msg_typename = 'SourceBreakpoint'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'line': typevim#Number(),
      \ 'column?': typevim#Number(),
      \ 'condition?': typevim#String(),
      \ 'hitCondition?': typevim#String(),
      \ 'logMessage?': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#FunctionBreakpoint() abort
  let l:vim_msg_typename = 'FunctionBreakpoint'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'name': typevim#String(),
      \ 'condition?': typevim#String(),
      \ 'hitCondition?': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Breakpoint() abort
  let l:vim_msg_typename = 'Breakpoint'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id?': typevim#Number(),
      \ 'verified': typevim#Bool(),
      \ 'message?': typevim#String(),
      \ 'source?': dapper#dap#Source(),
      \ 'line?': typevim#Number(),
      \ 'column?': typevim#Number(),
      \ 'endLine?': typevim#Number(),
      \ 'endColumn?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StepInTarget() abort
  let l:vim_msg_typename = 'StepInTarget'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': typevim#Number(),
      \ 'label': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#GotoTarget() abort
  let l:vim_msg_typename = 'GotoTarget'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'id': typevim#Number(),
      \ 'label': typevim#String(),
      \ 'line': typevim#Number(),
      \ 'column?': typevim#Number(),
      \ 'endLine?': typevim#Number(),
      \ 'endColumn?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#CompletionItem() abort
  let l:vim_msg_typename = 'CompletionItem'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'label': typevim#String(),
      \ 'text?': typevim#String(),
      \ 'type?': [
        \ 'method',  'function', 'constructor',      'field', 'variable',
        \  'class', 'interface',      'module',   'property',     'unit',
        \  'value',      'enum',     'keyword',    'snippet',     'text',
        \  'color',      'file',   'reference', 'customcolor'
        \ ],
      \ 'start?': typevim#Number(),
      \ 'length?': typevim#Number(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#Checksum() abort
  let l:vim_msg_typename = 'Checksum'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'algorithm': ['MD5', 'SHA1', 'SHA256', 'timestamp'],
      \ 'checksum': typevim#String(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ValueFormat() abort
  let l:vim_msg_typename = 'ValueFormat'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'hex?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#StackFrameFormat() abort
  let l:vim_msg_typename = 'StackFrameFormat'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'parameters?': typevim#Bool(),
      \ 'parameterTypes?': typevim#Bool(),
      \ 'parameterNames?': typevim#Bool(),
      \ 'parameterValues?': typevim#Bool(),
      \ 'line?': typevim#Bool(),
      \ 'module?': typevim#Bool(),
      \ 'includeAll?': typevim#Bool(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Extension(l:vim_msg_typename, dapper#dap#ValueFormat(), l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionOptions() abort
  let l:vim_msg_typename = 'ExceptionOptions'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'path?': typevim#List(),
      \ 'breakMode': ['never', 'always', 'unhandled', 'userUnhandled'],
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionPathSegment() abort
  let l:vim_msg_typename = 'ExceptionPathSegment'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'negate?': typevim#Bool(),
      \ 'names': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction


function! dapper#dap#ExceptionDetails() abort
  let l:vim_msg_typename = 'ExceptionDetails'
  if !has_key(s:MsgTypenameToInterface, l:vim_msg_typename)
    let l:prototype = {
      \ 'message?': typevim#String(),
      \ 'typeName?': typevim#String(),
      \ 'fullTypeName?': typevim#String(),
      \ 'evaluateName?': typevim#String(),
      \ 'stackTrace?': typevim#String(),
      \ 'innerException?': typevim#List(),
      \ }
    let s:MsgTypenameToInterface[l:vim_msg_typename] =
        \ typevim#make#Interface(l:vim_msg_typename, l:prototype)
  endif
  return s:MsgTypenameToInterface[l:vim_msg_typename]
endfunction
