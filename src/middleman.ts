import 'deep-equal';

import {isUndefined} from 'util';
import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

import * as Config from './config';
import {FrontTalker} from './fronttalker';
import {DapperEvent, DapperResponse, isDAPEvent, NULL_VIM_ID, typenameOf} from './messages';

import deepEqual = require('deep-equal');
import {clearTimeout} from 'timers';

// tslint:disable:no-any

/**
 * The middleman between dapper's VimL frontend and the debug adapter backend.
 *
 * Serves two main purposes:
 * - To deliver requests from the frontend to the backend, and to return
 * (properly addressed) responses from the backend to the frontend.
 * - To forward events (and reverse requests) from the backend to the
 * frontend.
 *
 * Middleman communicates with the frontend using a `FrontTalker` interface:
 * in actual use, it would use `NvimFrontTalker`, which communicates with
 * neovim through its remote plugin API; in testing, it can use
 * `MockFrontTalker`, which stores the frontend-bound responses/events that
 * Middleman delivers so that they can be checked in test cases.
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
  private wasAttachment = false;

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
  private teeEmit(eventName: string, ...args: any[]): boolean {
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
   * Returns true if this Middleman has a running DebugClient, and false
   * otherwise.
   */
  debugClientRunning(): boolean {
    return !deepEqual(this.dc, Middleman.EMPTY_DC);
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
  async startAdapter(startArgs: Config.StartArgs):
      Promise<DebugProtocol.InitializeResponse> {
    this.terminatePending = false;
    if (!deepEqual(this.dc, Middleman.EMPTY_DC)) {
      try {
        if (this.wasAttachment) {
          await this.disconnect();
        } else {
          await this.terminate();
        }
      } catch (e) {
        this.ft.report(
            'error', 'Failed to terminate running debug adapter!',
            e.toString());
        // try to kill it again
        await this.terminate();
      }
    }
    this.wasAttachment = false;

    const config = startArgs.adapter_config;
    this.dc = new DebugClient(
        config.runtime_env, config.exe_filepath, config.adapter_id);

    // monkey-patch DebugClient to "CC" the frontend on all incoming messages
    this.oldEmit = this.dc.emit.bind(this.dc);
    this.dc.emit = this.teeEmit.bind(this);

    this.dc.start();

    // need to start waiting for InitializedEvent before sending the
    // InitializeRequest, or else we may miss it entirely
    const initialBps = startArgs.debuggee_args.initial_bps || {};
    this.initialized = this.dc.waitForEvent('initialized');
    this.initialized.then(event => {
      console.log('Received InitializedEvent from adapter.');
      console.log(JSON.stringify(event));
      this.configureAdapter(
          initialBps.bps, initialBps.function_bps, initialBps.exception_bps);
    });

    const args: DebugProtocol.InitializeRequestArguments = {
      clientName: Middleman.CLIENT_NAME,
      adapterID: config.adapter_id,
      linesStartAt1: true,
      columnsStartAt1: true,
      locale: startArgs.locale,
      pathFormat: 'path',
      // TODO support the items below
      // supportsVariableType: true,
      // supportsVariablePaging: true,
      // supportsRunInTerminalRequest: true,
    };

    const response: DebugProtocol.InitializeResponse =
        await this.request('initialize', NULL_VIM_ID, args);

    this.capabilities = response.body as DebugProtocol.Capabilities;
    return response;
  }

  /**
   * Finish configuring the debug adapter, i.e. complete the 'startup
   * sequence.'
   *
   * Shall only be invoked after a call to `startAdapter`, *immediately* after
   * receiving a DebugProtocol.InitializedEvent.
   * @param {bps}     Ordinary breakpoints to be set on initialization.
   * @param {funcBps} Breakpoints to be set on particular functions.
   * @param {exBps}   Filters for exceptions on which to stop execution.
   */
  private async configureAdapter(
      bps?: DebugProtocol.SetBreakpointsArguments,
      funcBps?: DebugProtocol.SetFunctionBreakpointsArguments,
      exBps?: DebugProtocol.SetExceptionBreakpointsArguments):
      Promise<DebugProtocol.ConfigurationDoneResponse|DebugProtocol.Response> {
    const responses: Array<Promise<DebugProtocol.Response>> = [];
    if (!isUndefined(bps)) {
      console.log('User provided "normal" breakpoints; sending them.');
      responses.push(this.request('setBreakpoints', NULL_VIM_ID, bps));
    }
    if (!isUndefined(funcBps)) {
      console.log('User provided function breakpoints; sending them.');
      responses.push(
          this.request('setFunctionBreakpoints', NULL_VIM_ID, funcBps));
    }

    await Promise.all(responses);

    // send exception breakpoints, and then only send configurationDone if
    // supported
    if (isUndefined(exBps)) {
      // TODO reject if exBps contains filters not contained in Capabilities
      console.log(
          'User did not provide exception breakpoints. Setting defaults.');
      exBps = {filters: []};
    }
    const exBpsResp =
        await this.request('setExceptionBreakpoints', NULL_VIM_ID, exBps);
    if (this.capabilities.supportsConfigurationDoneRequest) {
      return await this.request('configurationDone', NULL_VIM_ID, {});
    }
    return exBpsResp;
  }

  /**
   * Gracefully (or ungracefully) kill the running debug adapter.
   */
  async terminate(restart = false):
      Promise<DebugProtocol.TerminateResponse|
              DebugProtocol.DisconnectResponse> {
    if (this.terminatePending || !this.capabilities.supportsTerminateRequest) {
      return this.disconnect();
    }
    this.terminatePending = true;
    const termResp = this.request('terminate', NULL_VIM_ID, {restart});
    const timeout = new Promise<void>(async (_, reject) => {
      const id = setTimeout(() => {
        // prevent erroneous timeout from an older, "stale" terminate request
        clearTimeout(id);
        reject();
      }, 5000);  // TODO magic number
    });

    const result = Promise.race([termResp, timeout]);
    return result.then(
        (fulfilled) => {
          // only reachable after successful termination
          this.dc = Middleman.EMPTY_DC;
          return fulfilled as DapperResponse;
        },
        () => {
          const msg = 'Terminate request timed out. Forcing disconnect.';
          this.ft.report('info', msg, '');
          return this.disconnect();
        });
  }

  /**
   * Detach from an already running debuggee.
   */
  async disconnect(restart = false, terminateDebuggee = false):
      Promise<DebugProtocol.DisconnectResponse> {
    try {
      this.terminatePending = false;
      const response =
          this.request('disconnect', NULL_VIM_ID, {restart, terminateDebuggee});
      // only reachable after successful detachment/forced adapter shutdown
      this.dc = Middleman.EMPTY_DC;
      return response;
    } catch (e) {
      this.ft.report('error', 'Disconnect failed!', e.toString());
      return {} as DebugProtocol.DisconnectResponse;
    }
  }

  /**
   * Wrapper around the `report()` function provided by the FrontTalker.
   */
  report(kind: string, brief: string, long: string, other?: any):
      Promise<void> {
    return this.ft.report(kind, brief, long, other);
  }

  /**
   * Send a request, forwarding the DebugAdapter's response to the frontend.
   *
   * Middleman should use this function internally as much as is reasonably
   * possible, so that the VimL frontend will be notified of the results of
   * its actions. Middleman's "vimID" is 0.
   * @param {command} The `command` property that would go in the corresponding
   *                  `DebugProtocol.Request`.
   * @param {vimID}   An ID for the VimL class instance that initiated the
   *                  request, so that the response can be "addressed" to the
   *                  original requester.
   * @param {args}    A `DebugProtocol.[*]Arguments` dictionary.
   */
  async request(command: string, vimID: number, args: any):
      Promise<DapperResponse> {
    try {
      this.ft.report(
          'debug', 'Sending request: ' + command, JSON.stringify(args));
      const resp = await this.dc.send(command, args) as DapperResponse;
      resp.vim_id = vimID;
      resp.vim_msg_typename = typenameOf(resp);
      this.ft.send(resp);  // actually send response to frontend
      return resp;  // mostly for test cases; neovim ignores async return values
    } catch (e) {
      this.ft.report(
          'error', command + ' request failed!',
          'vimID: ' + vimID + 'args: ' + JSON.stringify(args) + ', ' +
              e.toString());
      throw e;
    }
  }

  /**
   * Get the capabilities reported by the active debug adapter.
   */
  getCapabilities(): DebugProtocol.Capabilities {
    return this.capabilities;
  }
}
