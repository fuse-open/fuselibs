var v = require('./foo')
test.assert(v == 'foo', 'Requiring from dir should resolve to "foo/index.js" even when foo.js exists. Expected "foo", got "' + v + "'");
v = require('./bar')
test.assert(require('./bar') == 'baz', 'Requiring from file when dir exists with no index.js should resolve to file. Expected "baz", got "' + v + '"');
