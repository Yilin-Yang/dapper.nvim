import {DebugClient} from 'vscode-debugadapter-testsupport';

console.log('Hello, World!');

let dc : DebugClient;

dc = new DebugClient('node', './build/vscode-node-debug2/src/nodeDebug.js', 'node');
console.log('DebugClient object created.');

dc.start().then((res) => {
  console.log('Debug adapter started!');
  console.log('Trying initialization...');
}).catch((rej) => {
  console.log('Start debug adapter FAILED!');
  throw new Error(rej);
}).then((res) => {
  console.log('Debug adapter initialized!');
  console.log('Printing response:');
  console.log(res);
}).catch((rej) => {
  console.log('Initialization request failed!');
  throw new Error(rej);
});
