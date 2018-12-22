import {Neovim, NvimPlugin} from 'neovim';
// import {DebugProtocol} from 'vscode-debugprotocol';

/**
 * The middleman between dapper's VimL frontend and the debug adapter backend.
 */
class Middleman {
  /**
   * For manipulating the user-facing neovim instance.
   */
  private nvim: Neovim;

  constructor(api: NvimPlugin) {
    this.nvim = api.nvim;
  }

  success(): Promise<string> {
    console.log('invoked success function');
    return new Promise<string>(async (resolve, reject) => {
      console.log('entered promise');
      await this.nvim.call('dapper#receive', 'foo');
      resolve('succeeded from inside middleman');
    });
  }

  fail(): Promise<string> {
    return new Promise<string>(async (resolve, reject) => {
      await this.nvim.command('echoerr "failed from inside middleman"');
      reject('failed from inside middleman');
    });
  }

  // request(request): Promise<DebugProtocol.Response> {
  //   return new Promise<DebugProtocol.Response>(
  //     (resolve, reject) => {

  //     }
  //   );
  // }
}

export = Middleman;
