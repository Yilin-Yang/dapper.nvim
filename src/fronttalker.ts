import {DapperAnyMsg, DapperRequest} from './messages';

/**
 * The interface used to send and receive messages to/from the VimL frontend.
 *
 * Mimics the interface of a Node.js EventEmitter.
 */
export interface FrontTalker {
  /**
   * Forward a DebugProtocol.ProtocolMessage to the VimL frontend.
   */
  send(msg: DapperAnyMsg): void;

  /**
   * Subscribe to incoming requests from the VimL frontend.
   *
   * @param {reqType}   String compared against the `command` property of the
   *     incoming DebugProtocol.Request.
   * @param {callback}  The callback function.
   * @returns {this}    Reference to this FrontTalker.
   */
  // tslint:disable-next-line:no-any
  on(reqType: string|RegExp,
     callback: (req: DapperRequest) => any): FrontTalker;

  /**
   * Removes the given callback from the list of listeners, if present.
   *
   * @returns {this}    Reference to this FrontTalker.
   */
  // tslint:disable-next-line:no-any
  off(reqType: string|RegExp,
      callback: (req: DapperRequest) => any): FrontTalker;

  /**
   * Notify subscribers of a request from the VimL frontend.
   *
   * Intended to be invoked by the VimL frontend as a remote procedure call.
   * @returns {hadListeners}  Whether the given `reqName` had listeners.
   */
  emit(reqName: string, request: DapperRequest): boolean;
}
