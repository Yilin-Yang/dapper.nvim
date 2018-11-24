import {DebugClient} from 'vscode-debugadapter-testsupport';

console.log('Hello, World!');

let dc : DebugClient;

dc = new DebugClient('node', './build/vscode-node-debug2/src/nodeDebug.js', 'node');
console.log('DebugClient object created.');

dc.start().then((res) => {
  console.log('Debug adapter started!');
  console.log('Trying initialization...');
  return dc.initializeRequest();
}).then((res) => {
  console.log('Debug adapter initialized!');
  console.log(res);
});
// }).catch((rej) => {
//   console.log('Initialization request failed!');
//   throw new Error(rej);
// });

// dc.configurationSequence().then((res) => {
//   console.log('configurationDone');
//   console.log(res);
// }).catch((rej) => {
//   console.log('Configuration sequence failed.');
//   console.log('Printing configuration sequence failure message:');
//   console.log(rej);
// });
