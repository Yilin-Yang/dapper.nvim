import * as assert from 'assert';
import {describe, it} from 'mocha';
import {DebugProtocol} from 'vscode-debugprotocol';

import * as Config from '../src/config';
import {Middleman} from '../src/middleman';
import {MockFrontTalker} from '../src/mock_fronttalker';

import {MOCK_ADAPTER_CAPABILITIES, MOCK_ADAPTER_EXE_FPATH, STACK_FRAMES, TEST_README_FPATH, THREADS} from './test_readme';

const TIMEOUT_LEN = 5000;  // ms

let mm: Middleman;
const ft: MockFrontTalker = new MockFrontTalker();

const startArgs: Config.StartArgs = {
  adapter_config: {
    runtime_env: 'node',
    exe_filepath: MOCK_ADAPTER_EXE_FPATH,
    adapter_id: 'mock'
  },
  debuggee_args: {request: 'launch', name: 'test debuggee', args: {}},
  locale: 'en_US'
};
const launchArgs = {
  stopOnEntry: true,
  program: TEST_README_FPATH
} as DebugProtocol.LaunchRequestArguments;
startArgs.debuggee_args.args = launchArgs;

describe('Middleman initialization, mock debug adapter', () => {
  it('can be constructed with a mock FrontTalker', () => {
    mm = new Middleman(ft);
  });

  it('can start a mock debug adapter', async () => {
    const result = await mm.startAdapter(startArgs);
    assert.deepEqual(mm.getCapabilities(), MOCK_ADAPTER_CAPABILITIES);
    return result;
  }).timeout(TIMEOUT_LEN);

  it('will terminate an already running adapter before starting a new one',
     async () => {
       const result = await mm.startAdapter(startArgs);
       assert.deepEqual(mm.getCapabilities(), MOCK_ADAPTER_CAPABILITIES);
       return result;
     })
      .timeout(TIMEOUT_LEN);
});

describe('Middleman interaction, mock debug adapter', () => {
  it('can launch a "debuggee"', async () => {
    const launchRequestArgs = {
      noDebug: false,
      program: TEST_README_FPATH,
      stopOnEntry: true,
    };
    const result = await mm.request('launch', 3, launchRequestArgs);
    return result;
  }).timeout(TIMEOUT_LEN);

  let threadId: number;
  it('can retrieve a list of all active threads', async () => {
    threadId = THREADS[0].id;
    // console.log('expected: ' + JSON.stringify(expected));
    const threadsResp = await mm.request('threads', 4, {});
    assert.deepEqual(threadsResp.body.threads, THREADS);
    return threadsResp;
  });

  it('can retrieve the active stackframes', async () => {
    const stackFramesArgs = {
      threadId,
    };
    const stackResp = await mm.request('stackTrace', 4, stackFramesArgs);
    assert.deepEqual(stackResp.body.stackFrames, STACK_FRAMES);
    return stackResp;
  });
});

describe('Middleman termination, mock debug adapter', () => {
  it('can terminate the running debug adapter and debuggee process',
     async () => {
       const result = await mm.terminate();
       return result;
     })
      .timeout(TIMEOUT_LEN);
});
