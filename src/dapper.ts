import {NvimPlugin} from 'neovim';
import {DebugProtocol} from 'vscode-debugprotocol';

import * as Config from './config';
import {Middleman} from './middleman';
import {NvimFrontTalker} from './nvim_fronttalker';

// tslint:disable:no-any

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
export function start(args: Config.StartArgs): Promise<string> {
  return new Promise<string>(async (resolve, reject) => {
    try {
      const success = await middleman.startAdapter(
          args.runtime_env, args.exe_filepath, args.adapter_id, args.locale);
      if (!success) reject('Failed to start debug adapter!');
      resolve('Successfully initialized debug adapter.');
    } catch {
      // TODO debug log
      reject('Debug adapter threw an exception during initialization!');
    }
  });
}
export const FN_START_OPTIONS = {
  sync: false,
};

/**
 * Specify pre-launch configuration settings.
 */
export function configure(args: Config.InitialBreakpoints): void {
  // try {
  middleman.configureAdapter(args.bps, args.function_bps, args.exception_bps);
  // } catch (e) {
  // TODO log failure
  // }
}


export function request(command: string, vimID: number, args: any):
    Promise<DebugProtocol.Response> {
  return middleman.request(command, vimID, args);  // TODO
}
export const FN_REQUEST_OPTIONS = {
  sync: false
};
