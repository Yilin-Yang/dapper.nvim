import {DebugClient} from 'vscode-debugadapter-testsupport';
import {DebugProtocol} from 'vscode-debugprotocol';

console.log('Hello, World!');

let dc: DebugClient;

// dc = new DebugClient('node', './build/vscode-mock-debug/out/debugAdapter.js',
// 'mock');
dc = new DebugClient(
    'node',
    '/home/yiliny/plugin/dapper.nvim/build/vscode-mock-debug/out/debugAdapter.js',
    'mock');

dc.start()
    .then(response => {
      console.log('Debug adapter started!');
      return dc.initializeRequest();
    })
    .then(response => {
      console.log('Received initialization response!');
      console.log(response.body);
    });

dc.waitForEvent('initialized')
    .then(response => {
      console.log('Received initialized event.');
      console.log('Reporting that configuration is done.');
      return dc.configurationDoneRequest();
    })
    .then(response => {
      console.log('Initial configuration complete!');
      console.log(response.body);
      return dc.launch({
        program: '/home/yiliny/plugin/dapper.nvim/README.md',
        stopOnEntry: true
      });
    })
    .then(response => {
      console.log('Launched program!');
      console.log(response.body);
    });

// Program should immediately hit a breakpoint
dc.waitForEvent('stopped')
    .then(response => {
      console.log('Stopped execution.');
      console.log(
          'stop reason: ' + response.body.reason + '\n' +
          'thread id: ' + response.body.threadId);
      return dc.stackTraceRequest({threadId: response.body.threadId});
    })
    .then(response => {
      console.log('Obtained stack frame information!');
      console.log(response.body.stackFrames);
    });

// })
// .then(response => {
//   console.log('Launched program.');
//   return dc.setBreakpointsRequest(
//       {'source': Source.path('/home/yiliny/plugin/dapper.nvim/README.md'),
//        'breakpoints': [1,2,3]});
// });
