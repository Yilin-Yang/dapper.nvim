import * as assert from 'assert';
import {describe, it} from 'mocha';
import * as path from 'path';

import {MockFrontTalker} from '../src/mock_fronttalker';
import * as dapper from '../src/dapper';
import {StartArgs, InitialBreakpoints, DapperConfig} from '../src/config';

const TIMEOUT_LEN = 5000;  // ms
const ft: MockFrontTalker = new MockFrontTalker();

describe('dapper\'s remote plugin interface, facing nvim', () => {
  it('can initialize the Middleman', () => {
    dapper.initialize(ft);
  }),
  it('can start/configure the mock debug adapter', async () => {
    const startArgs: StartArgs = {
      runtime_env: 'node',
      exe_filepath: path.join(__dirname, '..', 'node_modules',
          'vscode-mock-debug', 'out', 'debugAdapter.js'),
      adapter_id: 'mock',
      locale: 'en-US'
    };
    const bps: InitialBreakpoints = {};
    const config: DapperConfig = {
      is_start: true,
      attributes: startArgs,
      breakpoints: bps,
    };
    const result = await dapper.startAndConfigure(config);
    return result;
  }).timeout(TIMEOUT_LEN);
  it('can deactivate the Middleman afterwards', async () => {
    const result = await dapper.terminate();
    assert.equal(result, true);
    return result;
  }).timeout(TIMEOUT_LEN);
});
