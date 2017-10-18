"use strict";

var assert = require("assert");
var Observable = require("../../Observable.js");

describe('observable list tests', function() {
    var observableList,
        kcount;
    before(function() {
        observableList = Observable(
            Observable(true),
            Observable(true),
            Observable(false)
        );

        kcount = observableList.count(function(x) { return x; });
        kcount.addSubscriber(function() {
            //do nothing
        });
    });

    describe('simple operations', function () {
        it('true-items count', function () {
            assert.equal(kcount.value, 2);
        });
        it('changing item [1] to false', function () {
            observableList.getAt(1).value = false;
            assert.equal(kcount.value, 1);
        });
        it('computed value', function () {
            var a = Observable(10);
            var b = Observable(10);
            var t = observableList.count();
            var c = Observable(function() {
                return a.value + b.value + t.value;
            });

            c.addSubscriber(function () {
                //do nothing
            });
            assert.equal(c.value, 23);

            a.value = 124;
            assert.equal(c.value, 137);

            observableList.add("eeee!");
            assert.equal(c.value, 138);
        });
        it('insertAt', function() {
            var o = Observable(1, 2, 3);
            o.addSubscriber(function () { });
            assert.equal(o.getAt(0), 1);
            o.insertAt(0, 123);
            assert.equal(o.getAt(0), 123);
            assert.equal(o.getAt(1), 1);
            assert.equal(o.getAt(2), 2);
            assert.equal(o.getAt(3), 3);
            o.insertAt(3, 223);
            assert.equal(o.getAt(0), 123);
            assert.equal(o.getAt(1), 1);
            assert.equal(o.getAt(2), 2);
            assert.equal(o.getAt(3), 223);
            assert.equal(o.getAt(4), 3);
            o.insertAt(5, 323);
            assert.equal(o.getAt(0), 123);
            assert.equal(o.getAt(1), 1);
            assert.equal(o.getAt(2), 2);
            assert.equal(o.getAt(3), 223);
            assert.equal(o.getAt(4), 3);
            assert.equal(o.getAt(5), 323);
        });
    });
});
