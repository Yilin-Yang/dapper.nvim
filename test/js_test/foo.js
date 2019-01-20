class Foo {
  constructor(int, float, string) {
    this.int = int;
    this.float = float;
    this.string = string;
  }

  bar(arg1, arg2) {
    console.log('arg1: ' + arg1 + ', arg2: ' + arg2);
    console.log('int: ' + this.int + ', float: ' + this.float +
        ', string: ' + this.string);
  }
}

module.exports = Foo;
