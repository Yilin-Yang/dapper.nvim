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
    assert.equal(testObj.emit('initialize', initializeRequest), true);
    assert.deepEqual(sub.getLastAndReset(), initializeRequest);
  });
  it('only calls back with types to which others have subscribed', () => {
    const testObj = new BasicFrontTalker();
    const sub = new MockSubscriber();
    testObj.on('initialize', sub.receive);
    assert.equal(testObj.emit('launch', launchRequest), false);
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
    assert.equal(testObj.emit('initialize', initializeRequest), true);
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
  it('correctly removes subscribers, in order', () => {
    const testObj = new BasicFrontTalker();
    const subArr =
        [new MockSubscriber(), new MockSubscriber(), new MockSubscriber()];
    for (let i = 0; i < subArr.length; ++i) {
      testObj.on('initialize', subArr[i].receive);
    }
    testObj.off('initialize', subArr[0].receive);

    // bind generates a new functor that won't compare equal to the original
    // subArr[1].receive
    testObj.off('initialize', subArr[1].receiveWrong.bind(subArr[1]));

    assert.equal(testObj.emit('initialize', initializeRequest), true);

    assert.deepEqual(subArr[0].getLastAndReset(), {});
    assert.deepEqual(subArr[1].getLastAndReset(), {});
    assert.deepEqual(subArr[2].getLastAndReset(), initializeRequest);
  });
  it('correctly removes single subscriber', () => {
    const testObj = new BasicFrontTalker();
    const sub = new MockSubscriber();
    testObj.on('initialize', sub.receive);
    testObj.off('initialize', sub.receive);
    assert.equal(testObj.emit('initialize', initializeRequest), false);
    assert.deepEqual(sub.getLastAndReset(), {});
  });
  it('correctly removes multiple subscribers', () => {
    const testObj = new BasicFrontTalker();
    const subArr =
        [new MockSubscriber(), new MockSubscriber(), new MockSubscriber()];
    for (let i = 0; i < subArr.length; ++i) {
      testObj.on('initialize', subArr[i].receive);
    }
    testObj.off('initialize', subArr[0].receive);
    testObj.off('initialize', subArr[1].receiveWrong.bind(subArr[1]));
    testObj.off('initialize', subArr[2].receive);

    assert.equal(testObj.emit('initialize', initializeRequest), false);

    assert.deepEqual(subArr[0].getLastAndReset(), {});
    assert.deepEqual(subArr[1].getLastAndReset(), {});
    assert.deepEqual(subArr[2].getLastAndReset(), {});
  });
});
