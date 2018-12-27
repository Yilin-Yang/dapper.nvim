import {Neovim, NvimPlugin} from 'neovim';
import {isUndefined} from 'util';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

import {DapperEvent, DapperRequest, DapperResponse, NULL_VIM_ID, typenameOf, isDAPEvent} from './messages';
import {FrontTalker} from './fronttalker';

/**
 * The middleman between dapper's VimL frontend and the debug adapter backend.
 */
export class Middleman {
  static readonly CLIENT_NAME: string = 'dapper.nvim';

  private static readonly EMPTY_DC: DebugClient = {} as DebugClient;
  private static readonly MATCH_EVERY: RegExp = new RegExp('');

  /**
   * For manipulating the user-facing neovim instance.
   */
  private ft: FrontTalker;
  private dc: DebugClient;
  private capabilities: DebugProtocol.Capabilities;

  // tslint:disable-next-line:no-any
  private oldEmit: (eventName: string, ...args: any[]) => boolean;

  constructor(ft: FrontTalker) {
    // subscribe to incoming requests, forward them to the adapter
    ft.on(Middleman.MATCH_EVERY, this.request.bind(this));
    this.ft = ft;
    this.dc = Middleman.EMPTY_DC;
    this.capabilities = {};

    // monkey-patch DebugClient to support 'subscribe to All'
    this.oldEmit = this.dc.emit.bind(this.dc);
    this.dc.emit = this.teeEmit.bind(this);
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
    if (isDAPEvent(args[0])) {
      const event = args[0] as DapperEvent;
      event.vim_id = NULL_VIM_ID;
      event.vim_msg_typename = typenameOf(event);
      this.ft.send(event);
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
   * @param {runtimeEnv}  The environment in which to run the debug adapter,
   *                      e.g. `python`, `node`.
   * @param {exeFilepath} The filepath to the debug adapter executable.
   * @param {adapterID}   The name of the debug adapter.
   * @return  {}  `true` when the initialization succeeded, `false` otherwise.
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
        console.log(e);
        resolve(false);
      }
    });
  }

  /**
   * Finish configuring the debug adapter, i.e. complete the 'startup
   * sequence.'
   *
   * Shall only be invoked after a call to `startAdapter`.
   * @param {bps}     Ordinary breakpoints to be set on initialization.
   * @param {funcBps} Breakpoints to be set on particular functions.
   * @param {exBps}   Filters for exceptions on which to stop execution.
   */
  async configureAdapter(
      bps?: DebugProtocol.SetBreakpointsArguments,
      funcBps?: DebugProtocol.SetFunctionBreakpointsArguments,
      exBps?: DebugProtocol.SetExceptionBreakpointsArguments):
      Promise<DebugProtocol.ConfigurationDoneResponse|DebugProtocol.Response> {
    // TODO reject if exBps contains filters not contained in Capabilities
    const responses: Array<Promise<DebugProtocol.Response>> = [];
    if (!isUndefined(bps)) {
      responses.push(this.dc.setBreakpointsRequest(bps));
    }
    if (!isUndefined(funcBps)) {
      responses.push(this.dc.setFunctionBreakpointsRequest(funcBps));
    }
    await Promise.all(responses);

    if (isUndefined(exBps)) {
      if (this.capabilities.supportsConfigurationDoneRequest) {
        return await this.dc.configurationDoneRequest({});
      } else {
        return await this.dc.setExceptionBreakpointsRequest({filters: ['any']});
      }
    }
    // send exception breakpoints, and only send configurationDone if
    // supported, to avoid clobbering user-set exception breakpoints
    const exBpsResp = await this.dc.setExceptionBreakpointsRequest(exBps);
    if (this.capabilities.supportsConfigurationDoneRequest) {
      return await this.dc.configurationDoneRequest({});
    }
    return exBpsResp;
  }

  /**
   * Send a request, returning the response from the DebugAdapter.
   */
  async request(req: DapperRequest): Promise<DapperResponse> {
    // make sure that this actually returns a value to the frontend?
    // TODO: emit the Response as an Event(?)
    const resp = await this.dc.send(req.command, req) as DapperResponse;
    resp.vim_id = req.vim_id;
    resp.vim_msg_typename = typenameOf(resp);
    return resp;
  }
}
