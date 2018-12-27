import * as assert from 'assert';
import {describe, it} from 'mocha';
import {DebugProtocol} from 'vscode-debugprotocol';

import {BasicFrontTalker} from '../src/basic_fronttalker';
import {DapperRequest} from '../src/messages';

import {MockSubscriber} from './mock_subscriber';

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
    const testObj = new BasicFrontTalker();
    const sub = new MockSubscriber();
    testObj.on('initialize', sub.receive);
    testObj.emit('initialize', initializeRequest);
    assert.deepEqual(sub.getLastAndReset(), initializeRequest);
  });
  it('only calls back with types to which others have subscribed', () => {
    const testObj = new BasicFrontTalker();
    const sub = new MockSubscriber();
    testObj.on('initialize', sub.receive);
    testObj.emit('launch', launchRequest);
    assert.deepEqual(sub.getLastAndReset(), {} as DapperRequest);
  });
  it('correctly calls back multiple subscribers to the same type', () => {
    const testObj = new BasicFrontTalker();
    const subDict: {[pattern: string]: MockSubscriber[]} = {};
    subDict['initialize'] =
        [new MockSubscriber(), new MockSubscriber(), new MockSubscriber()];
    subDict['launch'] = [new MockSubscriber()];
    subDict['threads'] = [new MockSubscriber()];
    for (const reqType in subDict) {
      if (typeof reqType === 'string') {
        const mockSubs = subDict[reqType];
        for (let i = 0; i < mockSubs.length; ++i) {
          const sub = mockSubs[i];
          testObj.on(reqType, (sub as MockSubscriber).receive);
        }
      }
    }
    testObj.emit('initialize', initializeRequest);
    for (let i = 0; i < subDict['initialize'].length; ++i) {
      const sub = subDict['initialize'][i];
      assert.deepEqual(sub.getLastAndReset(), initializeRequest);
    }
    for (let i = 0; i < subDict['launch'].length; ++i) {
      const sub = subDict['launch'][i];
      assert.deepEqual(sub.getLastAndReset(), {} as DapperRequest);
    }
    for (let i = 0; i < subDict['threads'].length; ++i) {
      const sub = subDict['threads'][i];
      assert.deepEqual(sub.getLastAndReset(), {} as DapperRequest);
    }
  });
});
