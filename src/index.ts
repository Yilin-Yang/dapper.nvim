import {DebugClient} from 'vscode-debugadapter-testsupport';

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
      console.log('foo');
      console.log(response.body);
    });

dc.waitForEvent('initialized')
    .then(response => {
      console.log('Received initialize response.');
      return dc.launch(
          {'program': '/home/yiliny/plugin/dapper.nvim/build/src/index.js'});
    })
    .then(response => {
      console.log('Launched program.');
      console.log(response.body);
    });
