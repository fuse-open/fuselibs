
var GlobalDI = require("../../DI");
var assert = require("assert");

describe("FuseJS/DI", function() {
    var DI = null;
    beforeEach(function() {
        DI = GlobalDI.createContainer();
    })

    it('evaluates transient dependencies every time they are injected', function() {
        var i = 0;
        function factory() { return i++; }
        DI.provideTransient("foo", factory);
        
        assert.strictEqual(DI("foo"), 0);
        assert.strictEqual(DI("foo"), 1);
    });

    it('only evaluates lazy dependencies once', function() {
        var i = 0;
        function factory() { return ++i; }
        DI.provideLazy("foo", factory);

        assert.strictEqual(DI("foo"), 1);
        assert.strictEqual(DI("foo"), 1);
    });

    it('throws if a dependency cannot be satisfied', function() {
        assert.throws(function() {
            DI("bazujiuofsd");
        });
    });

    it('can inject undefined', function() {
        DI.provide("foo", undefined);
        assert.doesNotThrow(function() {
            assert.strictEqual(DI("foo"), undefined);
        })
    });

    describe('#wrap()', function() {
        function unwrapped(a, b, c) {
            return [a,b,c];
        }
        var wrapped;

        beforeEach(function() {
            DI = GlobalDI.createContainer();
            wrapped = DI.wrap(unwrapped);
        })

        it('does not override explicitly provided dependencies', function() {
            DI.provide({
                a: "injected",
                b: "injected",
                c: "injected"
            });

            let result = wrapped("provided", undefined, null);
            assert.deepStrictEqual(["provided", "injected", null], result);
        })
    });
});