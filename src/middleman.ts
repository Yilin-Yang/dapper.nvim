import {Neovim, NvimPlugin} from 'neovim';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

import {DapperEvent, DapperRequest, DapperResponse, typenameOf, NULL_VIM_ID} from './messages';

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

  private oldEmit: (eventName:string, ...args:any[]) => boolean;

  constructor(api: NvimPlugin) {
    this.nvim = api.nvim;
    this.dc = Middleman.EMPTY_DC;
    this.capabilities = {};

    // monkey-patch DebugClient to support 'subscribe to All'
    this.oldEmit = this.dc.emit;
  }

  /**
   * Send `DebugProtocol.Event`s to the frontend, on top of emitting them normally.
   *
   * Comparable to the `tee` program available in most Unix terminals.
   */
  private teeEmit(eventName: string, ...args: any): boolean {
    // TODO: make sure this doesn't also redirect Responses
    if (args.length === 1 && (args[0] as DapperEvent).seq) {
      // assume that this is a DAP Event
      const event = args[0] as DapperEvent;
      event.vim_id = NULL_VIM_ID;
      event.vim_msg_typename = typenameOf(event);
      this.nvim.call('dapper#receive', event);
    }

    // perform ordinary event emission
    // TODO: test cases for emission
    return this.oldEmit.apply(this, [eventName] + args);
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
  startAdapter(
      runtimeEnv: string, exeFilepath: string, adapterID: string,
      locale: string): Promise<boolean> {
    return new Promise<boolean>(async (resolve, reject) => {
      try {
        // TODO: if dc != EMPTY_DC, terminate the still running process
        this.dc = new DebugClient(runtimeEnv, exeFilepath, adapterID);
        const args: DebugProtocol.InitializeRequestArguments = {
          clientName: Middleman.CLIENT_NAME,
          adapterID,
          linesStartAt1: true,
          columnsStartAt1: true,
          locale,
          // TODO support the items below
          // supportsVariableType: true,
          // supportsVariablePaging: true,
          // supportsRunInTerminalRequest: true,
        };
        const response: DebugProtocol.InitializeResponse =
            await this.dc.initializeRequest(args);
        this.capabilities = response.body as DebugProtocol.Capabilities;
        console.log(this.capabilities);
        resolve(true);
      } catch (e) {
        // TODO: log exception
        resolve(false);
      }
    });
  }

  /**
   * Send a request, returning the corresponding response from the DebugAdapter.
   */
  async request(req: DapperRequest): Promise<DapperResponse> {
    // make sure that this actually returns a value to the frontend?
    const resp = await this.dc.send(req.command, req) as DapperResponse;
    resp.vim_id = req.vim_id;
    resp.vim_msg_typename = typenameOf(resp);
    return resp;
  }
}

export = Middleman;
