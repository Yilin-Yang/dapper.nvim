import {Neovim, NvimPlugin} from 'neovim';
import {isUndefined} from 'util';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

import {DapperEvent, DapperRequest, DapperResponse, NULL_VIM_ID, typenameOf} from './messages';

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

  // tslint:disable-next-line:no-any
  private oldEmit: (eventName: string, ...args: any[]) => boolean;

  constructor(api: NvimPlugin) {
    this.nvim = api.nvim;
    this.dc = Middleman.EMPTY_DC;
    this.capabilities = {};

    // monkey-patch DebugClient to support 'subscribe to All'
    this.oldEmit = this.dc.emit;
  }

  /**
   * Send `DebugProtocol.Event`s to the frontend, on top of emitting them
   * normally.
   *
   * Comparable to the `tee` program available in most Unix terminals.
   */
  // tslint:disable-next-line:no-any
  private teeEmit(eventName: string, ...args: any[]): boolean {
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
    return this.oldEmit.apply(this, [eventName].concat(args));
  }

  /**
   * Start a debug adapter.
   *
   * Runs through the startup sequence for a protocol-compliant debug adapter:
   * starts the adapter, initializes it, logs the adapter's capabilities, then
   * sends 'configurationDone'.
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
        // TODO frontend needs to configureAdapter()
        resolve(true);
      } catch (e) {
        // TODO: log exception
        resolve(false);
      }
    });
  }

  /**
   * Finish configuring the debug adapter, i.e. complete the 'startup sequence.'
   *
   * Shall only be invoked after a call to `startAdapter`.
   * @param   bps         Ordinary breakpoints to be set on initialization.
   * @param   funcBps     Breakpoints to be set on particular functions.
   * @param   exBps       Filters for exceptions on which to stop execution.
   */
  configureAdapter(
      bps?: DebugProtocol.SetBreakpointsArguments,
      funcBps?: DebugProtocol.SetFunctionBreakpointsArguments,
      exBps?: DebugProtocol.SetExceptionBreakpointsArguments):
      Promise<DebugProtocol.ConfigurationDoneResponse|DebugProtocol.Response> {
    // TODO reject if exBps contains filters not contained in Capabilities
    // TODO: send all requests "in parallel"?
    if (!isUndefined(bps)) {
      this.dc.setBreakpointsRequest(bps);
    }
    if (!isUndefined(funcBps)) {
      this.dc.setFunctionBreakpointsRequest(funcBps);
    }
    if (isUndefined(exBps)) {
      return this.dc.configurationDoneRequest({});
    }
    // send exception breakpoints, and only send configurationDone if
    // supported, to avoid clobbering user-set exception breakpoints
    const exBpsResp = this.dc.setExceptionBreakpointsRequest(exBps);
    if (this.capabilities.supportsConfigurationDoneRequest) {
      return this.dc.configurationDoneRequest({});
    }
    return exBpsResp;
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
