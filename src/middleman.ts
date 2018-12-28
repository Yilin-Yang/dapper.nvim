import {isUndefined} from 'util';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

import {FrontTalker} from './fronttalker';
import {DapperEvent, DapperResponse, isDAPEvent, NULL_VIM_ID, typenameOf} from './messages';

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

  private initialized: Promise<DebugProtocol.Event>|undefined = undefined;
  private terminatePending = false;

  // tslint:disable-next-line:no-any
  private oldEmit: (eventName: string, ...args: any[]) => boolean;

  constructor(ft: FrontTalker) {
    // subscribe to incoming requests, forward them to the adapter
    ft.on(Middleman.MATCH_EVERY, this.request.bind(this));
    this.ft = ft;
    this.dc = Middleman.EMPTY_DC;
    this.capabilities = {};
    this.oldEmit = () => {
      return false;
    };
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
   * starts the adapter, initializes it, then sends 'configurationDone'.
   * @param {runtimeEnv}  The environment in which to run the debug adapter,
   *                      e.g. `python`, `node`.
   * @param {exeFilepath} The filepath to the debug adapter executable.
   * @param {adapterID}   The name of the debug adapter.
   * @return  {}  `true` when the initialization succeeded, `false` otherwise.
   */
  async startAdapter(
      runtimeEnv: string, exeFilepath: string, adapterID: string,
      locale = 'en-US'): Promise<DebugProtocol.InitializeResponse> {
    this.terminatePending = false;
    // TODO: if dc != EMPTY_DC, terminate the still running process
    this.dc = new DebugClient(runtimeEnv, exeFilepath, adapterID);
    const args: DebugProtocol.InitializeRequestArguments = {
      clientName: Middleman.CLIENT_NAME,
      adapterID,
      linesStartAt1: true,
      columnsStartAt1: true,
      locale,
      pathFormat: 'path',
      // TODO support the items below
      // supportsVariableType: true,
      // supportsVariablePaging: true,
      // supportsRunInTerminalRequest: true,
    };
    // only proceed with configuration after initialization is complete
    this.initialized = this.dc.waitForEvent('initialized');
    await this.dc.start();
    const response: DebugProtocol.InitializeResponse =
        await this.dc.initializeRequest(args);
    this.capabilities = response.body as DebugProtocol.Capabilities;

    // monkey-patch DebugClient to support 'subscribe to All'
    this.oldEmit = this.dc.emit.bind(this.dc);
    this.dc.emit = this.teeEmit.bind(this);

    // TODO frontend needs to configureAdapter()
    return response;
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
    // wait for initialization to complete before configuring
    await this.initialized;
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
   * Gracefully (or ungracefully) kill the running debug adapter.
   */
  async terminate(restart = false): Promise<DebugProtocol.TerminateResponse> {
    if (this.terminatePending || !this.capabilities.supportsTerminateRequest) {
      this.disconnect();
    }
    this.terminatePending = true;
    return await this.dc.terminateRequest({restart});
  }

  /**
   * Detach from an already running debuggee.
   */
  async disconnect(restart = false, terminateDebuggee = false):
      Promise<DebugProtocol.DisconnectResponse> {
    return this.dc.disconnectRequest({restart, terminateDebuggee});
  }

  /**
   * Send a request, returning the response from the DebugAdapter.
   * @param {command} The `command` property that would go in the corresponding
   *                  `DebugProtocol.Request`.
   * @param {vimID}   An ID for the VimL class instance that initiated the
   *                  request, so that the response can be "addressed" to the
   *                  original requester.
   * @param {args}    A `DebugProtocol.[*]Arguments` dictionary.
   */
  // tslint:disable-next-line:no-any
  async request(command: string, vimID: number, args: any):
      Promise<DapperResponse> {
    const resp = await this.dc.send(command, args) as DapperResponse;
    resp.vim_id = vimID;
    resp.vim_msg_typename = typenameOf(resp);
    this.ft.send(resp);  // actually send response to frontend
    return resp;  // mostly for test cases; neovim ignores async return values
  }

  /**
   * Get the capabilities reported by the active debug adapter.
   */
  getCapabilities(): DebugProtocol.Capabilities {
    return this.capabilities;
  }
}
