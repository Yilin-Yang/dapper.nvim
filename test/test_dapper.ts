import * as assert from 'assert';
import {describe, it} from 'mocha';

import {DebugProtocol} from 'vscode-debugprotocol';

import {MockFrontTalker} from '../src/mock_fronttalker';
import * as dapper from '../src/dapper';
import {DebugAdapterConfig, StartArgs, DebuggeeArgs} from '../src/config';

import {MOCK_ADAPTER_EXE_FPATH, THREADS, TEST_README_FPATH} from './test_readme';
import { DapperAnyMsg } from '../src/messages';

const TIMEOUT_LEN = 5000;  // ms
const ft: MockFrontTalker = new MockFrontTalker();

describe('dapper\'s remote plugin interface, facing nvim', () => {
  it('can initialize the Middleman', () => {
    dapper.initialize(ft);
  }),
  it('can start/configure the mock debug adapter and launch debuggee',
      async () => {
    const adapterConfig: DebugAdapterConfig = {
      runtime_env: 'node',
      exe_filepath: MOCK_ADAPTER_EXE_FPATH,
      adapter_id: 'mock',
    };
    const launchRequestArgs = {
      noDebug: false,
      program: TEST_README_FPATH,
      stopOnEntry: true,
    } as DebugProtocol.LaunchRequestArguments;
    const debuggeeArgs: DebuggeeArgs = {
      request: 'launch',
      name: 'mock',
      args: launchRequestArgs,
    };
    const startArgs: StartArgs = {
      adapter_config: adapterConfig,
      debuggee_args: debuggeeArgs,
      locale: 'en-US'
    };
    await dapper.startAndConfigure(startArgs);
    assert.ok(ft.hasReceived('InitializeResponse'));
    assert.ok(ft.hasReceived('ConfigurationDoneResponse'));
    assert.ok(ft.hasReceived('InitializedEvent'));
    return;
  }).timeout(TIMEOUT_LEN);
  // it('can launch a debuggee process and notify the frontend', async () => {
  //   const launchRequestArgs = {
  //     noDebug: false,
  //     program: TEST_README_FPATH,
  //     stopOnEntry: true,
  //   };
  //   await dapper.request('launch', 3, launchRequestArgs);
  //   const result = ft.getLast() as DapperAnyMsg;
  //   assert.equal(result.vim_id, 3);
  //   assert.equal(result.vim_msg_typename, 'LaunchResponse');
  //   return result;
  // }).timeout(TIMEOUT_LEN);
  it('can forward running threads to the frontend', async () => {
    await dapper.request('threads', 4, {});
    const threads = ft.getLast() as DapperAnyMsg;
    assert.equal(threads.vim_id, 4);
    assert.equal(threads.vim_msg_typename, 'ThreadsResponse');
    assert.deepEqual(
        (threads as DebugProtocol.ThreadsResponse).body.threads,
        THREADS);
  }).timeout(TIMEOUT_LEN);
  it('can deactivate the Middleman afterwards', async () => {
    const result = await dapper.terminate();
    assert.equal(result, true);
    const resp = ft.getLast() as DapperAnyMsg;
    assert.ok(
        resp.vim_msg_typename === 'TerminateResponse' ||
        resp.vim_msg_typename === 'DisconnectResponse');
    return result;
  }).timeout(TIMEOUT_LEN);
});
