"use strict";

var assert = require("assert");
var Observable = require("../../Observable.js");

function Task(done, work)
{
    this.work = Observable(work);
    this.checked = Observable(done);

    this.toString = function() {
        return "work: " + this.work;
    }
}

describe('task list tests', function() {
    var todoList,
        remainingCount;
    before(function() {
        todoList = Observable(
            new Task(true,5),
            new Task(false, 19),
            new Task(true, 3),
            new Task(true, 8),
            new Task(false, 18),
            new Task(false, 0),
            new Task(false, 11)
        );

        remainingCount = todoList.count(function(x) { return x.checked; });
        remainingCount.addSubscriber(function () {
            //do nothing;
        });
    });

    describe('simple operations', function () {
        it('checked items count', function () {
            assert.equal(remainingCount.value, 3);
        });
        it('removing first checked item', function () {
            todoList.remove(todoList.getAt(0));
            assert.equal(remainingCount.value, 2);
        });
        it('adding true-task', function () {
            todoList.add(new Task(true));
            assert.equal(remainingCount.value, 3);
        });
        it('changing task [0] to true', function () {
            todoList.getAt(0).checked.value = true;
            assert.equal(remainingCount.value, 4);
        });
        it('changing task [2] to false', function () {
            todoList.getAt(2).checked.value = false;
            assert.equal(remainingCount.value, 3);
        });
        it('tasks where work > 10', function () {
            var foo = todoList.where( function(x) { return (x.work.value + 2) > 10; });
            foo.addSubscriber(function () {
                //do nothing;
            });

            assert.equal(foo.length, 3);

            todoList.add(new Task(true, 9));
            assert.equal(foo.length, 4);
        });
    });
});