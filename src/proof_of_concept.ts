import {DebugClient} from 'vscode-debugadapter-testsupport';

console.log('Hello, World!');

let dc: DebugClient;

async function setup() {
  dc = new DebugClient(
      'node',
      '/home/yiliny/plugin/dapper.nvim/extensions/vscode-node-debug2/out/src/nodeDebug.js',
      'node2');
  dc.start();
  console.log(await dc.hitBreakpoint(
    { program: '/home/yiliny/plugin/dapper.nvim/test/js_test/index.js' },
    { path: '/home/yiliny/plugin/dapper.nvim/test/js_test/index.js', line: 1 },
    { line: 1 })
  );
  dc.stop();
}

setup();
