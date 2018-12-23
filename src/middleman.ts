import {Neovim, NvimPlugin} from 'neovim';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

/**
 * The middleman between dapper's VimL frontend and the debug adapter backend.
 */
class Middleman {
  static readonly CLIENT_NAME: string = 'dapper.nvim';

  private static readonly EMPTY_DC: DebugClient = {} as DebugClient;

  /**
   * For manipulating the user-facing neovim instance.
   */
  private nvim: Neovim;
  private dc: DebugClient;
  private capabilities: DebugProtocol.Capabilities;

  constructor(api: NvimPlugin) {
    this.nvim = api.nvim;
    this.dc = Middleman.EMPTY_DC;
    this.capabilities = {};
  }

  /**
   * Start a debug adapter.
   *
   * See DebugClient for additional parameter documentation.
   * @param   runtimeEnv  The environment in which to run the debug adapter,
   *                      e.g. `python`, `node`.
   * @param   exeFilepath The filepath to the debug adapter executable.
   * @param   adapterID   The name of the debug adapter.
   * @returns {} `true` when the initialization succeeded, `false` otherwise.
   */
  startAdapter(runtimeEnv: string, exeFilepath: string, adapterID: string): Promise<boolean> {
      return new Promise<boolean>(async (resolve, reject) => {
        try {
          // TODO: if dc != EMPTY_DC, terminate the still running process
          this.dc = new DebugClient(runtimeEnv, exeFilepath, adapterID);
          const args: DebugProtocol.InitializeRequestArguments = {
            clientName: Middleman.CLIENT_NAME,
            adapterID,
            linesStartAt1: true,
            columnsStartAt1: true,
            // TODO support the items below
            // supportsVariableType: true,
            // supportsVariablePaging: true,
            // supportsRunInTerminalRequest: true,
          };
          const response: DebugProtocol.InitializeResponse =
            await this.dc.initializeRequest(args);
          this.capabilities = response.body as DebugProtocol.Capabilities;
          resolve(true);
        } catch (e) {
          // TODO: log exception
          resolve(false);
        }
      });
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
