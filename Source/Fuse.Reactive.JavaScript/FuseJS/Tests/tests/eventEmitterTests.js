"use strict";

var assert = require("assert");
var Observable = require("../../Observable.js");
var EventEmitter = require("../../EventEmitter.js");

var Symb = typeof Symbol === 'undefined' ? function(x) { return x; } : Symbol;

function arraySetEquals(arr1, arr2) {
    assert.strictEqual(arr1.length, arr2.length);
    arr1.forEach(function(x) { assert(arr2.indexOf(x) !== -1); });
    arr2.forEach(function(x) { assert(arr1.indexOf(x) !== -1); });
}

var arrayEqual = assert.deepStrictEquals
    ? assert.deepStrictEqual
    : function(arr1, arr2) {
        assert.strictEqual(arr1.length, arr2.length);
        for (var i = 0; i < arr1.length; ++i) {
            assert.strictEqual(arr1[i], arr2[i]);
        }
    }


describe('EventEmitter tests', function() {
    it('registering and querying available events', function() {
        var sym = Symb('mySymbol');
        var emitter = new EventEmitter(sym, 'a', 'b', 'c');
        emitter.registerEvent(sym);
        emitter.registerEvent('a');
        emitter.registerEvent('d');
        emitter.registerEvent('e');
        arraySetEquals(emitter.eventNames(), [sym, 'a', 'b', 'c', 'd', 'e', 'error', 'newListener', 'removeListener']);
    });

    it('listening to and emitting events', function() {
        var emitter = new EventEmitter('a', 'b', 'c');
        var ran = false;
        var listener = function(arg1, arg2, arg3) {
            ran = true;
            assert.strictEqual(1, arg1);
            assert.strictEqual(2, arg2);
            assert.strictEqual(3, arg3);
        };
        emitter.on('a', listener);
        emitter.emit('a', 1, 2, 3);
        assert(ran);
        ran = false;
        emitter.removeListener('a', listener);
        emitter.emit('a', 1, 2, 3);
        assert(!ran);
    });

    it('add and remove multiple of the same listener', function() {
        var emitter = new EventEmitter('a');
        var ran = false;

        var emitAndAssertRun = function emitAndAssertRun() {
            ran = false;
            emitter.emit('a');
            assert(ran);
        }

        var listener = function() {
            ran = true;
        }
        emitter.on('a', listener);
        emitAndAssertRun();
        emitter.on('a', listener);
        emitAndAssertRun();
        emitter.removeListener('a', listener);
        emitAndAssertRun();
        emitter.removeListener('a', listener);
        emitter.removeListener('a', listener);
    });

    it('event emitter errors', function() {
        var emitter = new EventEmitter();
        assert.throws(function() {
            emitter.emit('error', 'A nice little error string');
        }, /A nice little error string/);
    });

    it('event argument count', function() {
        var emitter = new EventEmitter('argCount');
        var argCounts = [];
        emitter.on('argCount', function() {
            argCounts.push(arguments.length)
        });
        emitter.emit('argCount');
        emitter.emit('argCount', null);
        emitter.emit('argCount', null, null);
        emitter.emit('argCount', null, null, null);
        emitter.emit('argCount', null, null, null, null);
        emitter.emit('argCount', null, null, null, null, null);
        arrayEqual([0, 1, 2, 3, 4, 5], argCounts);
    });

    it('events that are not strings', function() {
        var sym = Symb('myEvent');
        var emitter = new EventEmitter(sym);
        var ran = false;
        emitter.on(sym, function() {
            ran = true;
        });
        emitter.emit(sym);
        assert(ran);
    });

    it('event ordering', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var state = 1;

        var listener1 = function() {
            assert.strictEqual(1, state);
            ++state;
        }

        var listener2 = function() {
            assert.strictEqual(2, state);
            ++state;
        }

        var listener3 = function() {
            assert.strictEqual(3, state);
            ++state;
        }

        emitter.on('a', listener1);
        emitter.on('a', listener2);
        emitter.on('a', listener3);

        emitter.emit('a');
        assert.strictEqual(4, state);

        state = 1;
        emitter.addListener('b', listener2);
        emitter.prependListener('b', listener1);
        emitter.addListener('b', listener3);

        emitter.emit('b');
        assert.strictEqual(4, state);

        state = 1;
        emitter.prependListener('c', listener2);
        emitter.addListener('c', listener3);
        emitter.prependListener('c', listener1);

        emitter.emit('c');
        assert.strictEqual(4, state);
    });

    it('invalid arguments', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var typeError = /^Error: There is no event of type "/;
        assert.throws(function() { emitter.addListener('x', function() { }); }, typeError);
        assert.throws(function() { emitter.on('x', function() { }); }, typeError);
        assert.throws(function() { emitter.prependListener('x', function() { }); }, typeError);
        assert.throws(function() { emitter.once('x', function() { }); }, typeError);
        assert.throws(function() { emitter.prependOnceListener('x', function() { }); }, typeError);
        assert.throws(function() { emitter.removeListener('x', function() { }); }, typeError);
        assert.throws(function() { emitter.emit('x'); }, typeError);
        assert.throws(function() { emitter.observe('x'); }, typeError);
        if (typeof Promise !== 'undefined')
            assert.throws(function() { emitter.promiseOf('x'); }, typeError);

        var listenerTypeError = /^TypeError: "listener" argument must be a function$/
        assert.throws(function() { emitter.addListener('a', 3); }, listenerTypeError);
        assert.throws(function() { emitter.on('a', 3); }, listenerTypeError);
        assert.throws(function() { emitter.prependListener('a', 3); }, listenerTypeError);
        assert.throws(function() { emitter.once('a', 3); }, listenerTypeError);
        assert.throws(function() { emitter.prependOnceListener('a', 3); }, listenerTypeError);
        assert.throws(function() { emitter.removeListener('a', 3); }, listenerTypeError);
    });

    it('error messages event name suggestions', function() {
        var emitter = new EventEmitter('abc 123', 'xyz 456', Symb('abc 123'), Symb('xyz 456'), 'lol1', 'lol2');
        assert.throws(function() { emitter.emit('abcc 123'); },
                /^Error: There is no event of type "abcc 123". Perhaps you meant "abc 123".$/);
        assert.throws(function() { emitter.emit('abd 123'); },
                /^Error: There is no event of type "abd 123". Perhaps you meant "abc 123".$/);
        assert.throws(function() { emitter.emit('ab 123'); },
                /^Error: There is no event of type "ab 123". Perhaps you meant "abc 123".$/);
        assert.throws(function() { emitter.emit('xxyz 456'); },
                /^Error: There is no event of type "xxyz 456". Perhaps you meant "xyz 456".$/);
        assert.throws(function() { emitter.emit('xyx 456'); },
                /^Error: There is no event of type "xyx 456". Perhaps you meant "xyz 456".$/);
        assert.throws(function() { emitter.emit('xyz 45'); },
                /^Error: There is no event of type "xyz 45". Perhaps you meant "xyz 456".$/);
        assert.throws(function() { emitter.emit('lol'); },
                /^Error: There is no event of type "lol". Perhaps you meant "lol1", or "lol2".$/);
    });

    it('once', function() {
        var emitter = new EventEmitter('a', 'b');
        var ran = false;
        emitter.once('a', function() { ran = true; });
        emitter.emit('a');
        assert(ran);
        ran = false;
        emitter.emit('a');
        assert(!ran);

        ran = false;
        emitter.prependOnceListener('b', function() { ran = true; });
        emitter.emit('b');
        assert(ran);
        ran = false;
        emitter.emit('b');
        assert(!ran);
    });

    it('once event ordering', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var state = 1;

        var listener1 = function() {
            assert.strictEqual(1, state);
            ++state;
        }

        var listener2 = function() {
            assert.strictEqual(2, state);
            ++state;
        }

        var listener3 = function() {
            assert.strictEqual(3, state);
            ++state;
        }

        emitter.once('a', listener1);
        emitter.once('a', listener2);
        emitter.once('a', listener3);

        emitter.emit('a');
        assert.strictEqual(4, state);

        state = 1;
        emitter.emit('a');
        assert.strictEqual(1, state);

        emitter.once('b', listener2);
        emitter.prependOnceListener('b', listener1);
        emitter.once('b', listener3);

        emitter.emit('b');
        assert.strictEqual(4, state);

        state = 1;
        emitter.emit('b');
        assert.strictEqual(1, state);

        emitter.prependOnceListener('c', listener2);
        emitter.once('c', listener3);
        emitter.prependOnceListener('c', listener1);

        emitter.emit('c');
        assert.strictEqual(4, state);

        state = 1;
        emitter.emit('c');
        assert.strictEqual(1, state);
    });

    it('newListener and removeListener', function() {
        var emitter = new EventEmitter('a', 'b', 'c');
        var events = [];
        emitter.on('newListener', function(event, listener) {
            if (event === 'removeListener') return;
            events.push('newListener');
            events.push(event);
            events.push(listener);
        });
        emitter.on('removeListener', function(event, listener) {
            events.push('removeListener');
            events.push(event);
            events.push(listener);
        });
        var f = function() { };
        var g = function() { };
        var h = function() { };
        emitter.addListener('a', f);
        emitter.removeListener('a', f);
        emitter.removeListener('b', g); // Does nothing
        emitter.prependListener('b', g);
        emitter.prependListener('c', h);
        emitter.removeListener('b', f); // Does nothing
        emitter.removeListener('b', g);
        emitter.removeListener('c', h);
        arrayEqual([
            'newListener', 'a', f,
            'removeListener', 'a', f,
            'newListener', 'b', g,
            'newListener', 'c', h,
            'removeListener', 'b', g,
            'removeListener', 'c', h], events);
    });

    it('removeListener in event callback', function() {
        var emitter = new EventEmitter('a', 'b', 'c');
        var ran1 = false;
        var listener1 = function() {
            ran1 = true;
            emitter.removeListener('a', listener2);
        };
        var ran2 = false;
        var listener2 = function() {
            ran2 = true;
        };
        emitter.on('a', listener1);
        emitter.on('a', listener2);
        emitter.emit('a');
        assert(ran1);
        assert(ran2);
        ran1 = false;
        ran2 = false;
        emitter.emit('a');
        assert(ran1);
        assert(!ran2);
    });

    it('removeListener in removeListener callback', function() {
        var emitter = new EventEmitter('a');

        function listener1() {
            throw new Error("Must not happen");
        }

        function listener2() {
            throw new Error("Must not happen 2");
        }

        var ran = false;
        emitter.on('removeListener', function(name, listener) {
            if (listener !== listener1) return;
            ran = true;
            this.removeListener('a', listener2);
            this.emit('a');
        });
        emitter.on('a', listener1);
        emitter.on('a', listener2);
        assert.doesNotThrow(function() { emitter.removeListener('a', listener1); });
        assert(ran);
    });

    it('removeListener and once', function() {
        var emitter = new EventEmitter('a');

        var ran = false;
        function listener() {
            ran = true;
        }

        emitter.once('a', listener);
        emitter.emit('a');
        assert(ran);

        ran = false;
        emitter.emit('a');
        assert(!ran);

        ran = false;
        emitter.once('a', listener);
        emitter.removeListener('a', listener);
        emitter.emit('a');
        assert(!ran);
    });

    it('removeAllListeners with specified type', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var aran = false;
        function alistener() {
            aran = true;
        }

        var bran = false;
        function blistener() {
            bran = true;
        }

        var cran = false;
        function clistener() {
            cran = true;
        }

        emitter.addListener('a', alistener);
        emitter.removeAllListeners('a');
        emitter.emit('a');
        assert(!aran);

        emitter.addListener('b', alistener);
        emitter.addListener('b', blistener);
        emitter.addListener('b', clistener);
        emitter.removeAllListeners('b');
        emitter.emit('b');
        assert(!aran && !bran && !cran);
    });

    it('removeAllListeners without specified type', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var aran = false;
        function alistener() {
            aran = true;
        }

        var bran = false;
        function blistener() {
            bran = true;
        }

        var cran = false;
        function clistener() {
            cran = true;
        }

        emitter.addListener('a', alistener);
        emitter.addListener('b', blistener);
        emitter.addListener('c', clistener);
        emitter.removeAllListeners();
        emitter.emit('a');
        emitter.emit('b');
        emitter.emit('c');
        assert(!aran && !bran && !cran);

        emitter.addListener('a', alistener);
        emitter.addListener('a', alistener);
        emitter.addListener('b', blistener);
        emitter.addListener('b', blistener);
        emitter.addListener('c', clistener);
        emitter.addListener('c', clistener);
        emitter.removeAllListeners();
        emitter.emit('a');
        emitter.emit('b');
        emitter.emit('c');
        assert(!aran && !bran && !cran);
    });

    it('removeAllListeners and removeListener callback', function() {
        var emitter = new EventEmitter('a', 'b', 'c');

        var aran = 0;
        function alistener() {
            ++aran;
        }

        var bran = 0;
        function blistener() {
            ++bran;
        }

        var cran = 0;
        function clistener() {
            ++cran;
        }

        emitter.on('removeListener', function(type, listener) {
            if (type === 'a' || type === 'b' || type === 'c')
                listener();
        });

        emitter.addListener('a', alistener);
        emitter.addListener('a', alistener);

        emitter.removeAllListeners('a');
        assert(aran === 2);

        aran = 0;

        emitter.addListener('a', alistener);
        emitter.addListener('a', alistener);
        emitter.addListener('b', blistener);
        emitter.addListener('b', blistener);
        emitter.addListener('c', clistener);
        emitter.addListener('c', clistener);

        emitter.removeAllListeners('b');

        assert(aran === 0 && bran === 2 && cran === 0);

        emitter.removeAllListeners();

        assert(aran === 2 && bran === 2 && cran === 2);
    });

    it('special event names', function() {
        var specialEventNames = ['__proto__', '__defineGetter__', 'toString', 'hasOwnProperty'];
        specialEventNames.forEach(function(eventName) {
            var emitter = new EventEmitter(eventName);
            var ran = false;
            var listener = function() {
                ran = true;
            }
            emitter.on(eventName, listener);
            emitter.emit(eventName);
            assert(ran);
            emitter.removeListener(eventName, listener);
        });
    });

    it('error', function() {
        var emitter = new EventEmitter();
        assert.throws(function() {
            emitter.emit('error', 'An error coming through');
        }, /An error coming through/);
        var handled = false;
        emitter.once('error', function(err) {
            handled = true;
            assert.strictEqual('A handled error', err);
        });
        emitter.emit('error', 'A handled error');
        assert(handled);
        assert.throws(function() {
            emitter.emit('error', 'Another error coming through');
        }, /Another error coming through/);
    });

    it('observe', function() {
        var emitter = new EventEmitter('x');
        var obs = emitter.observe('x');

        assert.strictEqual(obs, emitter.observe('x'));

        obs.addSubscriber(function() {});

        emitter.emit('x', 'a');
        assert.strictEqual('a', obs.value);
        emitter.emit('x', 'a', 'b', 'c');
        assert.strictEqual(3, obs.length);
        arrayEqual(['a', 'b', 'c'], obs.toArray());
    });

    it('observable subscriptions', function() {
        var emitter = new EventEmitter('x');

        var newListeners = 0;
        var removedListeners = 0;
        emitter.on('newListener', function(event) { if (event == 'x') ++newListeners; });
        emitter.on('removeListener', function(event) { if (event == 'x') ++removedListeners; });

        var obs = emitter.observe('x');

        assert.strictEqual(0, newListeners);
        assert.strictEqual(0, removedListeners);

        var sub = function() {};
        obs.addSubscriber(sub);
        var sub2 = function() {};
        obs.addSubscriber(sub2);

        assert.strictEqual(1, newListeners);
        assert.strictEqual(0, removedListeners);

        obs.removeSubscriber(sub);
        obs.removeSubscriber(sub2);

        assert.strictEqual(1, newListeners);
        assert.strictEqual(1, removedListeners);
    });

    if (typeof Promise !== 'undefined')
        it('promiseOf', function() {
            var emitter = new EventEmitter('x');

            assert.strictEqual(emitter.promiseOf('x'), emitter.promiseOf('x'));

            var ran = false;
            var errRan = false;

            var prom = emitter.promiseOf('x');
            prom.then(function(val) {
                ran = true;
                assert.strictEqual(42, val);
            },
            function(err) {
                errRan = true;
            }).then(function() {
                assert(ran);
                assert(!errRan);

                ran = false;
                emitter.emit('x', 42);
            }).then(function() {
                assert(!ran);
                assert(!errRan);

                assert.throws(emitter.emit('error', 'An error'), /An error/);
                assert(!errRan);

                assert.notStrictEqual(prom, emitter.promiseOf('x'));
            });
            emitter.emit('x', 42);
        });

    if (typeof Promise !== 'undefined')
        it('promiseOf errors', function() {
            var emitter = new EventEmitter('x');

            var ran = false;
            var errRan = false;
            emitter.promiseOf('x').then(function(val) {
                ran = true;
            },
            function(err) {
                errRan = true;
                assert.strictEqual(42, err);
            }).then(function() {
                assert(!ran);
                assert(errRan);

                errRan = false;
                assert.throws(function() { emitter.emit('error', 'An error') }, /An error/);
            }).then(function() {
                assert(!ran);
                assert(!errRan);
            });

            emitter.emit('error', 42);
        });
});
