'use strict';

var Observable = undefined;

function EventEmitter() {
	this._events = Object.create(null);
	// Built-in events
	this.registerEvent('newListener');
	this.registerEvent('removeListener');
	this.registerEvent('error');
	// Constructor-provided events
	for (var i = 0; i < arguments.length; ++i) {
		this.registerEvent(arguments[i]);
	}
}

module.exports = EventEmitter;

function validateListener(listener) {
	if (typeof listener !== 'function') {
		throw new TypeError('"listener" argument must be a function');
	}
}

function levenshteinDistance(s, t) {
	var slen = s.length;
	var tlen = t.length;
	if (slen === 0) {
		return tlen;
	}
	if (tlen === 0) {
		return slen;
	}
	var prev, cur, i, j, nextj, tmp;

	prev = [];
	cur = [];

	for (i = 0; i < tlen + 1; ++i) {
		cur[i] = i;
	}

	for (i = 0; i < slen; ++i) {
		tmp = prev;
		prev = cur;
		cur = tmp;

		cur[0] = i + 1;
		for (j = 0; j < tlen; ++j) {
			nextj = j + 1;
			cur[nextj] = Math.min(cur[j] + 1, prev[nextj] + 1, prev[j] + (s[i] === t[j] ? 0 : 1));
		}
	}
	return cur[tlen];
}

function getNearbyEventNames(target, type) {
	var sortedNames = typeof type === 'string'
		? target.eventNames().map(function(eventName) {
			return {
				eventName: eventName,
				dist: typeof eventName === 'string'
					? levenshteinDistance(type, eventName)
					: Number.MAX_VALUE
			};
		}).sort(function(x, y) { return x.dist - y.dist; })
		: [];

	if (sortedNames.length > 0 && sortedNames[0].dist < Number.MAX_VALUE) {
		var lowestDist = sortedNames[0].dist;
		var result = [];
		for (var i = 0; i < sortedNames.length && sortedNames[i].dist <= lowestDist + 2; ++i) {
			result.push(sortedNames[i].eventName);
		}
		return result;
	}
	return [];
}

function getEvent(target, type) {
	var result = target._events[type];
	if (!result) {
		var err = 'There is no event of type "' + type + '"';
		var nearby = getNearbyEventNames(target, type)
			.map(function(x, i, arr) {
				return i === arr.length - 1 && arr.length > 1
					? 'or "' + x + '"'
					: '"' + x + '"';
			}).join(', ');
		if (nearby.length > 0) {
			err += '. Perhaps you meant ' + nearby + '.';
		}
		throw new Error(err);
	}
	return result;
}

EventEmitter.prototype.registerEvent = function registerEvent(type) {
	if (!this._events[type]) {
		this._events[type] = { listeners: [] };
	}
	return this;
}

EventEmitter.prototype.addListener = function addListener(type, listener) {
	validateListener(listener);
	var list = getEvent(this, type).listeners;
	this.emit('newListener', type, listener);
	list.push(listener);
	return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.prependListener = function prependListener(type, listener) {
	validateListener(listener);
	var list = getEvent(this, type).listeners;
	this.emit('newListener', type, listener);
	list.unshift(listener);
	return this;
}

function wrapOnce(target, type, listener) {
	var fired = false;
	function result() {
		target.removeListener(type, result);
		if (!fired) {
			fired = true;
			listener.apply(target, arguments);
		}
	}
	// So we can find the original listener in removeListener
	result.listener = listener;
	return result;
}

EventEmitter.prototype.once = function once(type, listener) {
	validateListener(listener);
	this.on(type, wrapOnce(this, type, listener));
	return this;
}

EventEmitter.prototype.prependOnceListener = function once(type, listener) {
	validateListener(listener);
	this.prependListener(type, wrapOnce(this, type, listener));
	return this;
}

function removeListenerAt(target, type, list, index) {
	var listener = list.splice(index, 1)[0];
	target.emit('removeListener', type, listener.listener ? listener.listener : listener);
}

if (!Array.prototype.findIndex) {
	Object.defineProperty(Array.prototype, 'findIndex', {
		value: function(predicate) {
			'use strict';
			if (this == null) {
				throw new TypeError('Array.prototype.findIndex called on null or undefined');
			}
			if (typeof predicate !== 'function') {
				throw new TypeError('predicate must be a function');
			}
			var list = Object(this);
			var length = list.length >>> 0;
			var thisArg = arguments[1];
			var value;

			for (var i = 0; i < length; i++) {
				value = list[i];
				if (predicate.call(thisArg, value, i, list)) {
					return i;
				}
			}
			return -1;
		},
		enumerable: false,
		configurable: false,
		writable: false
	});
}

EventEmitter.prototype.removeListener = function removeListener(type, listener) {
	validateListener(listener);
	var list = getEvent(this, type).listeners;
	var index = list.findIndex(function(x) {
		return x === listener || x.listener && x.listener === listener;
	});
	if (index >= 0) {
		removeListenerAt(this, type, list, index);
	}
	return this;
}

EventEmitter.prototype.removeAllListeners = function(type) {
	// Remove everything
	if (arguments.length === 0) {
		var self = this;
		this.eventNames().forEach(function(eventName) {
			if (eventName !== 'removeListener')
				self.removeAllListeners(eventName);
		});
		this.removeAllListeners('removeListener');
	}
	// Remove all listeners listening to `type`
	else {
		var list = getEvent(this, type).listeners;
		while (list.length > 0) {
			removeListenerAt(this, type, list, list.length - 1);
		}
	}
}

EventEmitter.prototype.emit = function emit(type) {
	var list = getEvent(this, type).listeners;
	if (list.length > 0) {
		var args = Array.prototype.slice.call(arguments, 1);
		var self = this;
		list.slice().forEach(function(f) {
			f.apply(self, args);
		});
		return true;
	}
	else if (type === 'error') {
		var e = arguments[1];
		throw e instanceof Error
			? e
			: new Error('Uncaught, unspecified "error" event. (' + e + ')');
	}
	return false;
}

var reflectOwnKeys = typeof Reflect !== 'undefined' && Reflect.ownKeys // ES6 feature
	? Reflect.ownKeys
	: (Object.getOwnPropertyNames
		? (Object.getOwnPropertySymbols
			? function(obj) {
				return Object.getOwnPropertyNames(obj).concat(Object.getOwnPropertySymbols(obj));
			}
			: Object.getOwnPropertyNames)
		: Object.keys);

EventEmitter.prototype.eventNames = function eventNames() {
	return reflectOwnKeys(this._events);
}

EventEmitter.prototype.observe = function observe(type) {
	var event = getEvent(this, type);
	var cachedObservable = event.observable;
	if (cachedObservable) {
		return cachedObservable;
	}
	if (!Observable) {
		Observable = require('FuseJS/Observable');
	}
	var result = Observable();
	var listener = function() {
		if (arguments.length === 1) {
			result.value = arguments[0];
		}
		else {
			result.refreshAll(Array.prototype.slice.call(arguments));
		}
	}
	var self = this;
	result._addSubscriptionWatcher( function() { 
		self.addListener(type, listener); 
	}, function() { 
		self.removeListener(type, listener); 
	});
	event.observable = result;
	return result;
}

EventEmitter.prototype.promiseOf = function promiseOf(type) {
	var event = getEvent(this, type);
	var cachedPromise = event.promise;
	if (cachedPromise) {
		return cachedPromise;
	}
	var self = this;
	var result = new Promise(function(resolve, reject) {
		var listener = function listener() {
			delete event.promise;
			self.removeListener('error', errorListener);
			resolve.apply(null, arguments);
		}
		var errorListener = function errorListener() {
			delete event.promise;
			self.removeListener(type, listener);
			reject.apply(null, arguments);
		}
		self.once(type, listener);
		self.once('error', errorListener);
	});
	event.promise = result;
	return result;
}
