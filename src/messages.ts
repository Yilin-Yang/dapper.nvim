/**
 *  Types and helper functions for working with DebugProtocol messages.
 */

import {DebugProtocol} from 'vscode-debugprotocol';
import DPRequest = DebugProtocol.Request;
import DPResponse = DebugProtocol.Response;
import DPEvent = DebugProtocol.Event;

export const NULL_VIM_ID = 0;

/**
 *  The additional properties needed by the VimL frontend.
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

function firstCharToUpper(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

export function typenameOf(msg: DPRequest|DPResponse|DPEvent): string {
  if ((msg as DPEvent).event) {
    const evt: string = (msg as DPEvent).event;
    return firstCharToUpper(evt) + 'Event';
  } else if ((msg as DPResponse).request_seq) {
    const com: string = (msg as DPResponse).command;
    return firstCharToUpper(com) + 'Response';
  } else if ((msg as DPRequest).command) {
    const com: string = (msg as DPRequest).command;
    return firstCharToUpper(com) + 'Request';
  }
  throw new TypeError(
      'Given message doesn\'t seem to be a DebugProtocol type: ' + msg as
      string);
}
