import {DebugClient} from 'vscode-debugadapter-testsupport';

console.error('Hello, World!');

let dc : DebugClient;

// dc = new DebugClient('node', './build/vscode-mock-debug/out/debugAdapter.js', 'mock');
dc = new DebugClient('node', '/home/yiliny/plugin/dapper.nvim/build/vscode-mock-debug/out/debugAdapter.js', 'mock');

dc.start().then(response => {
  console.error('Debug adapter started!');
  return dc.initializeRequest();
}).then(response => {
  console.error('foo');
  console.error(response.body);
});

dc.waitForEvent('initialized').then(response => {
  console.error('Received initialize response.');
  return dc.launch({'program': '/home/yiliny/plugin/dapper.nvim/build/src/index.js'});
}).then(response => {
  console.error('Launched program.');
  console.error(response.body);
});
