/*interface EventListener
 {
 void handleEvent(Event event);
 }
 interface EventTarget
 {
 void addEventListener(string type, EventListener? callback, boolean capture = false);
 void removeEventListener(string type, EventListener? callback, boolean capture	= false);
 bool dispatchEvent(Event event); //https://dom.spec.whatwg.org/#concept-event-dispatch
 }*/
//Adopted from https://github.com/WebReflection/event-target
/* Copyright (C) 2013 by Andrea Giammarchi, @WebReflection

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.*/

EventTarget = (function() {

    "use strict";

    var PREFIX = "@@",
        EventTarget = {},
        descriptor = {
            // in ES5 does not bother with enumeration
            configurable: true,
            value: null
        },
        defineProperty = Object.defineProperty,
        indexOf = [].indexOf,
        has = EventTarget.hasOwnProperty;

    function configure(obj, prop, value) {
        descriptor.value = value;
        defineProperty(obj, prop, descriptor);
        descriptor.value = null;
    }

    function on(self, type, listener) {
        var array;
        if (has.call(self, type)) {
            array = self[type];
        } else {
            configure(self, type, array = []);
        }
        if (indexOf.call(array, listener) < 0) {
            array.push(listener);
        }
    }

    function dispatch(self, type, evt) {
        var array, current, i;
        if (has.call(self, type)) {
            evt.target = self;
            array = self[type].slice(0);
            for (i = 0; i < array.length; i++) {
                current = array[i];
                if (typeof current === "function") {
                    current.call(self, evt);
                } else if (typeof current.handleEvent === "function") {
                    current.handleEvent(evt);
                }
            }
        }
    }

    function off(self, type, listener) {
        var array, i;
        if (has.call(self, type)) {
            array = self[type];
            i = indexOf.call(array, listener);
            if (-1 < i) {
                array.splice(i, 1);
                if (!array.length) {
                    delete self[type];
                }
            }
        }
    }

    configure(EventTarget, "addEventListener", function addEventListener(type, listener) {
        on(this, PREFIX + type, listener);
    });

    configure(EventTarget, "dispatchEvent", function dispatchEvent(evt) {
        dispatch(this, PREFIX + evt.type, evt);
    });

    configure(EventTarget, "removeEventListener", function removeEventListener(type, listener) {
        off(this, PREFIX + type, listener);
    });

    var EventTargetWithProto = {};
    EventTargetWithProto.prototype = {
        addEventListener: EventTarget.addEventListener,
        removeEventListener: EventTarget.removeEventListener,
        dispatchEvent: EventTarget.dispatchEvent
    };
    return EventTargetWithProto;

})();

if (typeof window !== 'undefined') {
    Window.prototype.addEventListener = EventTarget.prototype.addEventListener;
    Window.prototype.removeEventListener = EventTarget.prototype.removeEventListener;
    Window.prototype.dispatchEvent = EventTarget.prototype.dispatchEvent;

    window.EventTarget = EventTarget;
}