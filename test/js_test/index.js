const Foo = require('./foo');

function throwError() {
  throw new Error('Somebody set us up the bomb!');
}

console.log('Hello, world!');
console.log(process.argv);

for (let arg of process.argv) {
  if (arg === 'construct') {
    var foo = new Foo(1, 2.0, 'foo');
    foo.bar('nergle', 'bergle');
  } else if (arg === 'error') {
    throwError();
  }
}
