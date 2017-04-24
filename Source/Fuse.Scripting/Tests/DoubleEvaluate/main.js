this.evalACount = 0;
this.evalBCount = 0;

var obj = require("./a");
var innerobj = require('./b');

test.assert(obj.name === 'a-web');
test.assert(innerobj.name === 'b-web')

test.assert(this.evalACount === 1, 'a-web should only evaluate once, count was ' + this.evalACount);
test.assert(this.evalBCount === 1, 'b-web should only evaluate once, count was ' + this.evalBCount);