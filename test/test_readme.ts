import * as path from 'path';
import * as fs from 'fs';

import {DebugProtocol} from 'vscode-debugprotocol';

/**
 * The filepath to the `TEST_README` "source file."
 */
export const TEST_README_FPATH: string = path.join(__dirname, 'TEST_README.md');

/**
 * The compiled mock debug adapter `exe_filepath`.
 */
export const MOCK_ADAPTER_EXE_FPATH: string = path.join(
    __dirname, '..', 'node_modules',
    'vscode-mock-debug', 'out', 'debugAdapter.js');

/**
 * The capabilities that should be returned by the mock debug adapter.
 */
export const MOCK_ADAPTER_CAPABILITIES: DebugProtocol.Capabilities = {
    supportsConfigurationDoneRequest: true,
    supportsEvaluateForHovers: true,
    supportsStepBack: true};

/**
 * The threads that should be returned by the mock debug adapter, after stopping
 * on `TEST_README.md`.
 *
 * Compare to: `DebugProtocol.ThreadsResponse.body.threads`
 */
export const THREADS: DebugProtocol.Thread[] = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'TEST_README_threads.json'), 'utf8'));

/**
 * The stack trace that should be returned by the mock debug adapter, after
 * stopping on the first line of `TEST_README.md`.
 *
 * Compare to: `DebugProtocol.StackTraceResponse.body.stackFrames`
 */
export const STACK_FRAMES: DebugProtocol.StackTraceResponse = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'TEST_README_stackframes.json'),
        'utf8'));
