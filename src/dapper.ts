import {DebugProtocol} from 'vscode-debugprotocol';

import * as Config from './config';
import {FrontTalker} from './fronttalker';
import {Middleman} from './middleman';
import {isVimList} from './nvim';

// tslint:disable:no-any

let middleman: Middleman;

function rejectBadArgs(funcname: string, args: any[]): void {
  const err =
      'Bad argument types in call to ' + funcname + ': ' + JSON.stringify(args);
  console.log(err);
  throw new Error(err);
}

/**
 * Initialize Middleman singleton with nvim API object.
 */
export function initialize(ft: FrontTalker): void {
  middleman = new Middleman(ft);
}


export function startAndConfigureUnpack(args: any[]): Promise<boolean> {
  try {
    let config = undefined;
    if (Config.isStartArgs(args)) {
      config = args as Config.StartArgs;
    } else if (isVimList(args) && Config.isStartArgs(args[0])) {
      config = args[0];
    } else {
      rejectBadArgs('startAndConfigure', args);
    }
    return startAndConfigure(config);
  } catch (e) {
    middleman.report('error', 'Start/Configuration failed!', e.toString());
    return Promise.resolve<boolean>(true);
  }
}
/**
 * Start a debug adapter, optionally setting breakpoints (during pre-launch
 * configuration).
 */
export function startAndConfigure(config: Config.StartArgs): Promise<boolean> {
  console.log('Received call to startAndConfigure.');
  console.log('Given args: ' + JSON.stringify(config));
  return new Promise<boolean>(async (resolve, reject) => {
    const args = config.adapter_config as Config.DebugAdapterConfig;
    const started = await middleman.startAdapter(
        args.runtime_env, args.exe_filepath, args.adapter_id, config.locale);
    if (!started) reject('Failed to start debug adapter!');

    const dbgArgs = config.debuggee_args;
    const bps = dbgArgs.initial_bps;
    let configured;
    if (bps) {
      configured = await middleman.configureAdapter(
          bps.bps, bps.function_bps, bps.exception_bps);
    } else {
      configured = await middleman.configureAdapter();
    }
    if (!configured) reject('Failed to configure debug adapter!');

    let launchedOrAttached;
    if (dbgArgs.request === 'launch' || dbgArgs.request === 'attach') {
      launchedOrAttached =
          await middleman.request(dbgArgs.request, 0, dbgArgs.args);
    } else {
      reject('Bad request type: ' + dbgArgs.request);
    }
    if (!launchedOrAttached) reject('Failed to launch/attach to debuggee!');

    resolve(true);
  });
}
export const FN_START_AND_CONFIGURE_OPTIONS = {
  sync: false
};

/**
 * Terminate a running debug adapter process.
 */
export function terminateUnpack(args: any[]): Promise<boolean> {
  try {
    let bad = false;
    let restart = undefined;
    if (typeof args === 'boolean') {
      restart = args;
    } else if (isVimList(args)) {
      restart = args[0];
      if (typeof restart !== 'boolean') bad = true;
    }
    if (bad) {
      rejectBadArgs('terminate', args);
    }
    return terminate(restart);
  } catch (e) {
    middleman.report('error', 'Terminate request failed!', e.toString());
    return Promise.resolve(false);
  }
}
export async function terminate(restart = false): Promise<boolean> {
  console.log('Received call to terminate.');
  if (!middleman.debugClientRunning()) {
    throw new Error('Debug client not running!');
  }
  return middleman.terminate(restart).then(() => true, () => false);
}
export const FN_TERMINATE_OPTIONS = {
  sync: false
};

export function requestUnpack(args: any[]): Promise<DebugProtocol.Response> {
  try {
    if (!args.hasOwnProperty('length') || args.length !== 3) {
      rejectBadArgs('request', args);
    }
    const command = args[0];
    const vimID = args[1];
    const argDict = args[2];

    if (typeof command !== 'string' || typeof vimID !== 'number' ||
        (typeof argDict !== 'object' && argDict !== undefined)) {
      rejectBadArgs('request', args);
    }

    return request(command, vimID, argDict);
  } catch (e) {
    middleman.report('error', 'Request failed!', e.toString());
    return Promise.resolve({} as DebugProtocol.Response);
  }
}
export function request(command: string, vimID: number, args: any):
    Promise<DebugProtocol.Response> {
  console.log('Received request in dapper.request: ');
  console.log('command:' + JSON.stringify(command));
  console.log('vimID:' + JSON.stringify(vimID));
  console.log('args:' + JSON.stringify(args));
  if (!middleman.debugClientRunning()) {
    throw new Error('Debug client not running!');
  }
  return middleman.request(command, vimID, args);
}
export const FN_REQUEST_OPTIONS = {
  sync: false
};
