import * as assert from 'assert';
import {describe, it} from 'mocha';

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

describe('Middleman initialization', () => {
  it('can be constructed with a mock FrontTalker', () => {
    mm = new Middleman(ft);
  });
  it('can start a mock debug adapter', async () => {
    const result = await mm.startAdapter(
        'node',
        '/home/yiliny/plugin/dapper.nvim/node_modules/vscode-mock-debug/out/debugAdapter.js',
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
describe('Middleman termination', () => {
  it('can terminate the running debug adapter and debuggee process', async () => {
     const result = await mm.terminate();
     return result;
  }).timeout(TIMEOUT_LEN);
});
