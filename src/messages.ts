/**
 * Types and helper functions for working with DebugProtocol messages.
 */

import {DebugProtocol} from 'vscode-debugprotocol';
import DPRequest = DebugProtocol.Request;
import DPResponse = DebugProtocol.Response;
import DPEvent = DebugProtocol.Event;

export const NULL_VIM_ID = 0;

/**
 * The additional properties needed by the VimL frontend.
 */
export interface DapperMessage {
  /**
   * Dapper-specific ID of the initiating requester/recipient.
   * If none is applicable (e.g. if this message is an event), shall be 0.
   */
  vim_id: number;

  /**
   * The full, human-readable 'name' of the messagetype.
   * Values: 'ErrorResponse', 'ThreadEvent', 'LaunchRequest', etc.
   */
  vim_msg_typename: string;
}

export type DapperRequest = DapperMessage&DPRequest;
export type DapperResponse = DapperMessage&DPResponse;
export type DapperEvent = DapperMessage&DPEvent;
export type DapperAnyMsg = DapperRequest|DapperResponse|DapperEvent;

function firstCharToUpper(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export function typenameOf(msg: DPRequest|DPResponse|DPEvent): string {
  const type: string = msg.type;
  if (type === 'event') {
    const evt: string = (msg as DPEvent).event;
    return firstCharToUpper(evt) + 'Event';
  } else if (type === 'response') {
    const com: string = (msg as DPResponse).command;
    return firstCharToUpper(com) + 'Response';
  } else if (type === 'request') {
    const com: string = (msg as DPRequest).command;
    return firstCharToUpper(com) + 'Request';
  }
  throw new TypeError(
      'Given message doesn\'t seem to be a DebugProtocol type: ' + msg as
      string);
}

// tslint:disable:no-any
export function isDAP(arg: any): arg is DebugProtocol.ProtocolMessage {
  return arg.hasOwnProperty('seq') && arg.hasOwnProperty('type');
}

export function isDAPRequest(arg: any): arg is DebugProtocol.Request {
  return isDAP(arg) && arg.hasOwnProperty('command') &&
      !arg.hasOwnProperty('request_seq');
}

export function isDAPEvent(arg: any): arg is DebugProtocol.Event {
  return isDAP(arg) && arg.hasOwnProperty('event');
}

export function isDAPResponse(arg: any): arg is DebugProtocol.Response {
  return isDAP(arg) && arg.hasOwnProperty('request_seq');
}
