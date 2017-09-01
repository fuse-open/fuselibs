var a = require('relative/submodule/a');
var b = require('relative/submodule/b');
test.assert(a.foo == b.foo, 'a and b share foo through a relative require');
