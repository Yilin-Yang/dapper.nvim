import {DebugProtocol} from 'vscode-debugprotocol';

import * as Config from './config';
import {FrontTalker} from './fronttalker';
import {Middleman} from './middleman';

// tslint:disable:no-any

let middleman: Middleman;

/**
 * Initialize Middleman singleton with nvim API object.
 */
export function initialize(ft: FrontTalker): void {
  middleman = new Middleman(ft);
}

/**
 * Start a debug adapter, optionally setting breakpoints (during pre-launch
 * configuration).
 */
export function startAndConfigure(config: Config.DapperConfig):
    Promise<boolean> {
  return new Promise<boolean>(async (resolve, reject) => {
    if (!config.is_start || !config.attributes.hasOwnProperty('runtime_env')) {
      reject('Attaching to a running process is currently unsupported.');
    }
    const args = config.attributes as Config.StartArgs;
    const started = await middleman.startAdapter(
        args.runtime_env, args.exe_filepath, args.adapter_id, args.locale);
    if (!started) resolve(false);

    const bps = config.breakpoints;
    const configured = await middleman.configureAdapter(
        bps.bps, bps.function_bps, bps.exception_bps);
    if (!configured) resolve(false);
    resolve(true);
  });
}
export const FN_START_AND_CONFIGURE_OPTIONS = {
  sync: false
};

/**
 * Terminate a running debug adapter process.
 */
export function terminate(restart = false): Promise<boolean> {
  const term = new Promise<boolean>(async (resolve) => {
    await middleman.terminate(restart);
    resolve(true);
  });
  const timeout = new Promise<boolean>((resolve, reject) => {
    const id = setTimeout(() => {
      // prevent erroneous timeout from an older, "stale" terminate request
      clearTimeout(id);

      reject('Terminate request timed out.');
      return false;
    }, 5000);
  });
  return Promise.race([term, timeout]);
}
export const FN_TERMINATE_OPTIONS = {
  sync: false
};

export function request(command: string, vimID: number, args: any):
    Promise<DebugProtocol.Response> {
  return middleman.request(command, vimID, args);  // TODO
}
export const FN_REQUEST_OPTIONS = {
  sync: false
};
