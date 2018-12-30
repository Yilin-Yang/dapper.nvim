import {DebugProtocol} from 'vscode-debugprotocol';

export interface StartArgs {
  runtime_env: string;
  exe_filepath: string;
  adapter_id: string;
  locale: string;
}

export interface AttachArgs {
  // tslint:disable-next-line:no-any
  __restart: any;
}

export interface InitialBreakpoints {
  bps?: DebugProtocol.SetBreakpointsArguments;
  function_bps?: DebugProtocol.SetFunctionBreakpointsArguments;
  exception_bps?: DebugProtocol.SetExceptionBreakpointsArguments;
}

export interface DapperConfig {
  is_start: boolean;
  attributes: StartArgs|AttachArgs;
  breakpoints: InitialBreakpoints;
}

// tslint:disable:no-any
export function isDapperConfig(arg: any): arg is DapperConfig {
  return arg.hasOwnProperty('is_start') && arg.hasOwnProperty('attributes') &&
      arg.hasOwnProperty('breakpoints');
}
