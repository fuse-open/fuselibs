var a = require('absolute/submodule/a');
var b = require('absolute/b');
test.assert(a.foo().foo === b.foo, 'require works with absolute identifiers');
