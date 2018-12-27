import {NvimPlugin} from 'neovim';
import {DebugProtocol} from 'vscode-debugprotocol';

import {DapperEvent, DapperRequest, DapperResponse} from './messages';
import {Middleman} from './middleman';
import {NvimFrontTalker} from './nvim_fronttalker';

let middleman: Middleman;

/**
 * Initialize Middleman singleton with nvim API object.
 * @param api  nvim node-client API.
 */
export function initialize(api: NvimPlugin): void {
  middleman = new Middleman(new NvimFrontTalker(api));
}

/**
 * Start a debug adapter.
 */
export function start(
    env: string, exe: string, adapter: string,
    locale = 'en-US'): Promise<string> {
  return new Promise<string>(async (resolve, reject) => {
    try {
      const success: boolean =
          await middleman.startAdapter(env, exe, adapter, locale);
      if (!success) reject('Failed to start debug adapter!');
      resolve('Successfully initialized debug adapter.');
    } catch {
      reject('Debug adapter threw an exception during initialization!');
    }
  });
}
export const CM_START_OPTIONS = {
  sync: false,
  nargs: '+'
};

export function configure(
    bps?: DebugProtocol.SetBreakpointsArguments,
    funcBps?: DebugProtocol.SetFunctionBreakpointsArguments,
    exBps?: DebugProtocol.SetExceptionBreakpointsArguments): void {
  // try {
  middleman.configureAdapter(bps, funcBps, exBps);
  // } catch (e) {
  // TODO log failure
  // }
}


export function request(req: DapperRequest): Promise<DebugProtocol.Response> {
  return middleman.request(req);  // TODO
}
export const FN_REQUEST_OPTIONS = {
  sync: false
};
