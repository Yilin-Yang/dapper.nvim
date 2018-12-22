import {NvimPlugin} from 'neovim';
import Middleman = require('./middleman');
import {DebugProtocol} from 'vscode-debugprotocol';

let middleman: Middleman;

/**
 * Initialize Middleman singleton with nvim API object.
 * @param api   nvim node-client API.
 */
export function initialize(api: NvimPlugin): void {
  middleman = new Middleman(api);
}

/**
 * Start a debug adapter.
 */
export function start(adapterID: string, command?: string): Promise<string> {
  return new Promise<string>(async (resolve, reject) => {
    try {
      const msg: string = await middleman.success();
      resolve(msg);
    } catch {
      reject('failed from inside start');
    }
  });
}
export const CM_START_OPTIONS = {
  sync: false,
  nargs: '+'
};

export function resolve_two_seconds() {
  return new Promise<string>((resolve, reject) => {
    try {
      // note, this return value is ignored in async calls
      setTimeout(() => {
        resolve('resolved!');
      }, 2000);
    } catch (e) {
      reject(e.what);
    }
  });
}

export function return_dict() {
  return new Promise<DebugProtocol.ProtocolMessage>((resolve, reject) => {
    try {
      const dict = {
        seq: 1,
        type: 'response',
        vim_id: 0,
        vim_msg_typename: 'ProtocolMessage'
      };
      resolve(dict);
    } catch (e) {
      reject(e.what);
    }
  });
}
export const FN_REQUEST_OPTIONS = {
  sync: true
};
