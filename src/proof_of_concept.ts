import {DebugClient} from 'vscode-debugadapter-testsupport';

console.log('Hello, World!');

let dc: DebugClient;

// Discovery:
//  The sequence diagram given in the DAP Overview isn't strictly linear.
//
//  The breakpoint configuration/etc. needs to happen *immediately after*
//  receiving the InitializedEvent, which can happen totally asynchronously with
//  re: to the rest of the startup process.
//
//  It's possible to receive an InitializedEvent without having sent an
//  InitializationRequest?

async function setup() {
  dc = new DebugClient(
      'node',
      '/home/yiliny/plugin/dapper.nvim/extensions/vscode-node-debug2/out/src/nodeDebug.js',
      'node2');
  dc.start();
  dc.configurationSequence().then(response => {
    console.log(response);
  });
  dc.waitForEvent('stopped').then(event => {
    console.log(event);
  });
  await dc
      .launch({
        program: '/home/yiliny/plugin/dapper.nvim/test/js_test/index.js',
        stopOnEntry: true
      })
      .then(response => {
        console.log(response);
      });
  await dc.threadsRequest()
      .then(response => {
        console.log(response.body.threads);
        return dc.stackTraceRequest({threadId: response.body.threads[0].id});
      })
      .then(response => {
        console.log(JSON.stringify(response));
      });
  // console.log(await dc.hitBreakpoint(
  //   { program: '/home/yiliny/plugin/dapper.nvim/test/js_test/index.js' },
  //   { path: '/home/yiliny/plugin/dapper.nvim/test/js_test/index.js', line: 1
  //   }, { line: 1 })
  // );
  dc.stop().then(response => {
    console.log(response);
  });
}

setup();
