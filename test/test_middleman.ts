import * as assert from 'assert';
import {describe, it} from 'mocha';
import * as path from 'path';
import * as fs from 'fs';

import {DebugProtocol} from 'vscode-debugprotocol';

import {Middleman} from '../src/middleman';
import {MockFrontTalker} from '../src/mock_fronttalker';

const TIMEOUT_LEN = 5000;  // ms

let mm: Middleman;
const ft: MockFrontTalker = new MockFrontTalker();

const mockCapabilities: DebugProtocol.Capabilities = {
    supportsConfigurationDoneRequest: true,
    supportsEvaluateForHovers: true,
    supportsStepBack: true};

describe('Middleman initialization, mock debug adapter', () => {
  it('can be constructed with a mock FrontTalker', () => {
    mm = new Middleman(ft);
  });

  it('can start a mock debug adapter', async () => {
    const result = await mm.startAdapter(
        'node',
        path.join(__dirname, '..', 'node_modules', 'vscode-mock-debug',
            'out', 'debugAdapter.js'),
        'mock');
    assert.deepEqual(mm.getCapabilities(), mockCapabilities);
    return result;
  }).timeout(TIMEOUT_LEN);

  it('can configure the mock debug adapter', async () => {
    const result = await mm.configureAdapter();
    return result;
  }).timeout(TIMEOUT_LEN);
});

describe('Middleman interaction, mock debug adapter', () => {
  it('can launch a "debuggee"', async () => {
    const launchRequestArgs = {
      noDebug: false,
      program: path.join(__dirname, 'TEST_README.md'),
      stopOnEntry: true
    };
    const result = await mm.request('launch', 3, launchRequestArgs);
    return result;
  }).timeout(TIMEOUT_LEN);

  let threadId: number;
  it('can retrieve a list of all active threads', async () => {
    const expected =
        JSON.parse(
            fs.readFileSync(path.join(__dirname, 'TEST_README_threads.json'),
                'utf8'));
    threadId = expected[0].id;
    // console.log('expected: ' + JSON.stringify(expected));
    const threadsResp = await mm.request('threads', 4, {});
    assert.deepEqual(threadsResp.body.threads, expected);
    return threadsResp;
  });

  it('can retrieve the active stackframes', async () => {
    const stackFramesArgs = {
      threadId,
    };
    const expected =
        JSON.parse(
            fs.readFileSync(path.join(__dirname, 'TEST_README_stackframes.json'),
                'utf8'));
    // console.log('expected: ' + JSON.stringify(expected));
    const stackResp = await mm.request('stackTrace', 4, stackFramesArgs);
    assert.deepEqual(stackResp.body.stackFrames, expected);
    return stackResp;
  });
});

describe('Middleman termination, mock debug adapter', () => {
  it('can terminate the running debug adapter and debuggee process', async () => {
     const result = await mm.terminate();
     return result;
  }).timeout(TIMEOUT_LEN);
});
