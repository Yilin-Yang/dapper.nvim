import * as assert from 'assert';
import {describe, it} from 'mocha';
import * as path from 'path';

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
    assert.equal(result, true);
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
    // const launchRequestArgs = {
    //   noDebug: false,
    //   program: './TEST_README.md',
    //   stopOnEntry: true
    // };
    // TODO: refine Middleman interface, only pass 'args' structs, not
    // full-blown requests
    // const result = await mm.request(launchRequestArgs);
    const result = true;
    return result;
  });

  // it('can retrieve a list of all active threads', async () => {
  // });
});

describe('Middleman termination, mock debug adapter', () => {
  it('can terminate the running debug adapter and debuggee process', async () => {
     const result = await mm.terminate();
     return result;
  }).timeout(TIMEOUT_LEN);
});
