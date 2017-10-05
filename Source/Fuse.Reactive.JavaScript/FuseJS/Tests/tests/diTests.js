
var GlobalDI = require("../../DI");
var assert = require("assert");

describe("FuseJS/DI", function() {
    var DI = null;
    beforeEach(function() {
        DI = GlobalDI.createContainer();
    });

	it("only accepts string or object", function() {
		[1, NaN, undefined, null, Infinity].forEach(function(v) {
			assert.throws(function() { DI(v) })
		})
	});

	it("can inject from prototype", function() {
		DI(Object.create({ foo: "bar" }));
		assert.strictEqual(DI("foo"), "bar");
	});

	it("evaluates dependencies on demand", function() {
		function Foo() {
			this.i = 0;
		}
		Object.defineProperty(Foo.prototype, "bar", {
			get: function() { return this.i++; }
		});

		DI(new Foo());

		assert.strictEqual(DI("bar"), 0);
		assert.strictEqual(DI("bar"), 1);
		assert.strictEqual(DI("bar"), 2);
	});
});