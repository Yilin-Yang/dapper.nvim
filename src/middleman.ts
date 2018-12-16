import {NvimPlugin} from 'neovim';
// import {DebugProtocol} from 'vscode-debugprotocol';

/**
 * The middleman between dapper's VimL frontend and the debug adapter backend.
 */
class Middleman {
  constructor(private api: NvimPlugin) {}

  success(): Promise<string> {
    return new Promise<string>(
      (resolve, reject) => {
        resolve('succeeded from inside middleman');
      }
    );
  }

  fail(): Promise<string> {
    return new Promise<string>(
      (resolve, reject) => {
        reject('failed from inside promise');
      }
    );
  }

  // request(request): Promise<DebugProtocol.Response> {
  //   return new Promise<DebugProtocol.Response>(
  //     (resolve, reject) => {

  //     }
  //   );
  // }
}

export = Middleman;
