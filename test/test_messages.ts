import * as assert from 'assert';
import {describe, it} from 'mocha';
import {DebugProtocol} from 'vscode-debugprotocol';

import {typenameOf, Report, ErrorReport, StatusReport} from '../src/messages';

describe('typenameOf', () => {
  it('recognizes DebugProtocol.Event as an "Event"', () => {
    const msg: DebugProtocol.Event = {
      seq: 0,
      type: 'event',
      event: '',
    };
    assert.equal(typenameOf(msg), 'Event');
  });
  it('recognizes DebugProtocol.Request as a "Request"', () => {
    const msg: DebugProtocol.Request = {
      seq: 0,
      type: 'request',
      command: '',
    };
    assert.equal(typenameOf(msg), 'Request');
  });
  it('recognizes DebugProtocol.Response as a "Response"', () => {
    const msg: DebugProtocol.Response = {
      seq: 1,
      type: 'response',
      command: '',
      request_seq: 0,
      success: true,
    };
    assert.equal(typenameOf(msg), 'Response');
  });
  it('recognizes Report as a "Report"', () => {
    const msg: Report = {
      seq: 1,
      type: 'report',
      kind: '',
      brief: 'foobar',
      long: 'foobarfoobar',
    };
    assert.equal(typenameOf(msg), 'Report');
  });
  it('recognizes ErrorReport', () => {
    const msg: ErrorReport = {
      seq: 1,
      type: 'report',
      kind: 'error',
      brief: 'foobar',
      long: 'foobarfoobar',
    };
    assert.equal(typenameOf(msg), 'ErrorReport');
  });
  it('recognizes StatusReport', () => {
    const msg: StatusReport = {
      seq: 1,
      type: 'report',
      kind: 'status',
      brief: 'foobar',
      long: 'foobarfoobar',
    };
    assert.equal(typenameOf(msg), 'StatusReport');
  });
  it('recognizes ThreadEvent', () => {
    const msg: DebugProtocol.Event = {
      seq: 0,
      type: 'event',
      event: 'thread',
    };
    assert.equal(typenameOf(msg), 'ThreadEvent');
  });
  it('recognizes InitializedEvent', () => {
    const msg: DebugProtocol.Event = {
      seq: 0,
      type: 'event',
      event: 'initialized',
    };
    assert.equal(typenameOf(msg), 'InitializedEvent');
  });
  it('recognizes ThreadsRequest"', () => {
    const msg: DebugProtocol.ThreadsRequest = {
      seq: 0,
      type: 'request',
      command: 'threads',
    };
    assert.equal(typenameOf(msg), 'ThreadsRequest');
  });
  it('recognizes ThreadsResponse"', () => {
    const msg: DebugProtocol.ThreadsResponse = {
      seq: 1,
      request_seq: 0,
      success: true,
      type: 'response',
      command: 'threads',
      body: {threads: [] as DebugProtocol.Thread[]}
    };
    assert.equal(typenameOf(msg), 'ThreadsResponse');
  });
  it('recognizes TerminateThreadsResponse"', () => {
    const msg: DebugProtocol.TerminateThreadsResponse = {
      seq: 1,
      request_seq: 0,
      success: true,
      type: 'response',
      command: 'terminateThreads',
    };
    assert.equal(typenameOf(msg), 'TerminateThreadsResponse');
  });
  it('recognizes LaunchResponse"', () => {
    const msg: DebugProtocol.LaunchResponse = {
      seq: 1,
      request_seq: 0,
      success: true,
      type: 'response',
      command: 'launch',
    };
    assert.equal(typenameOf(msg), 'LaunchResponse');
  });
  it('recognizes LoadedSourcesRequest"', () => {
    const msg: DebugProtocol.LoadedSourcesRequest = {
      seq: 1,
      type: 'request',
      command: 'loadedSources',
      arguments: {} as DebugProtocol.LoadedSourcesArguments,
    };
    assert.equal(typenameOf(msg), 'LoadedSourcesRequest');
  });
});
