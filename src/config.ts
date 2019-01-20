import {DebugProtocol} from 'vscode-debugprotocol';

export interface DebugAdapterConfig {
  runtime_env: string;
  exe_filepath: string;
  adapter_id: string;
}

export interface InitialBreakpoints {
  bps?: DebugProtocol.SetBreakpointsArguments;
  function_bps?: DebugProtocol.SetFunctionBreakpointsArguments;
  exception_bps?: DebugProtocol.SetExceptionBreakpointsArguments;
}

export interface DebuggeeArgs {
  request: string;
  name: string;
  args: DebugProtocol.LaunchRequestArguments|
      DebugProtocol.AttachRequestArguments;
  initial_bps?: InitialBreakpoints;
}

export interface VSCodeAttributes {
  preLaunchTask?: string;
  postLaunchTask?: string;
  internalConsoleOptions?: string;
  debugServer?: string;
}

export interface StartArgs {
  adapter_config: DebugAdapterConfig;
  debuggee_args: DebuggeeArgs;
  vscode_attr?: VSCodeAttributes;
  locale: string;
}

// tslint:disable:no-any
export function isStartArgs(arg: any): arg is StartArgs {
  return arg.hasOwnProperty('adapter_config') &&
      arg.hasOwnProperty('debuggee_args') &&
      arg.hasOwnProperty('vscode_attr') && arg.hasOwnProperty('locale');
}
