import * as assert from 'assert';
import {describe, it} from 'mocha';
import {DebugProtocol} from 'vscode-debugprotocol';

import {BasicFrontTalker} from '../src/basic_fronttalker';
import {DapperRequest} from '../src/messages';

const testSubscriber = {
  lastRequest: {} as DapperRequest,
  receive(msg: DapperRequest): void {
    this.lastRequest = {...msg} as DapperRequest;
  },
  getLast(): DapperRequest {
    const toReturn = {...this.lastRequest};  // shallow copy by spread
    this.lastRequest = {} as DapperRequest;  // reset variable
    return toReturn;
  }
};
const testObj = new BasicFrontTalker();

const initializeRequest: DapperRequest = {
  vim_id: 0,
  vim_msg_typename: 'InitializeRequest',
  seq: 0,
  type: 'request',
  command: 'initialize',
  arguments: {},
};
const launchRequest: DapperRequest = {
  vim_id: 0,
  vim_msg_typename: 'LaunchRequest',
  seq: 0,
  type: 'request',
  command: 'launch',
  arguments: {},
};

describe('BasicFrontTalker', () => {
  it('allows subscription to incoming Requests', () => {
    testObj.on('initialize', testSubscriber.receive.bind(testSubscriber));
    testObj.emit('initialize', initializeRequest);
    assert.deepEqual(testSubscriber.getLast(), initializeRequest);
  });
  it('only calls back with types to which others have subscribed', () => {
    testObj.emit('launch', launchRequest);
    assert.deepEqual(testSubscriber.getLast(), {} as DapperRequest);
  });
});
