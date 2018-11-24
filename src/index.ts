import {DebugClient} from 'vscode-debugadapter-testsupport';

console.log('Hello, World!');

let dc : DebugClient;

dc = new DebugClient('node', './build/vscode-mock-debug/out/debugAdapter.js', 'mock');

dc.start().then((res) => {
  console.log('Debug adapter started!');
  console.log('Trying initialization...');
  return dc.initializeRequest();
}).then((res) => {
  console.log('Debug adapter initialized!');
  console.log(res);
}).catch((rej) => {
  console.log('Initialization request failed!');
  throw new Error(rej);
});
