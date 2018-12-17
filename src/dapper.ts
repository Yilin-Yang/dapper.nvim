import {NvimPlugin} from 'neovim';
import Middleman = require('./middleman');

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
  return new Promise<string>(
    async (resolve, reject) => {
      try {
        const msg: string = await middleman.success();
        resolve(msg);
      } catch {
        reject('failed from inside start');
      }
    }
  );
}
export const CM_START_OPTIONS = {
  sync: false,
  nargs: '+'
};

export function request() {
  return new Promise<string>(
    (resolve, reject) => {
      try {
        // note, this return value is ignored in async calls
        setTimeout(() => {resolve('resolved!');}, 2000);
      } catch (e) {
        reject(e.what);
      }});
}
export const FN_REQUEST_OPTIONS = {
  sync: false
};
