"use strict";

function ArraySet(initialItems) {
	if (initialItems == null) {
		initialItems = [];
	}
	else if(!(initialItems instanceof Array)) {
		throw new Error("Only arrays may be used as initial ArraySet items.");
	}
	else {
		initialItems = initialItems.slice();
	}

	Object.defineProperty(this, "_items", {
		value: initialItems,
		configurable: false,
		enumerable: false,
		writable: false,
	});
}

ArraySet.prototype.has = function(item) {
	return this._items.indexOf(item) >= 0;
}

ArraySet.prototype.clear = function() {
	this._items.length = 0;
}

ArraySet.prototype.add = function(item) {
	if(this.has(item)) {
		return;
	}
	this._items.push(item);

	return this;
}

ArraySet.prototype.delete = function(item) {
	var index = this._items.indexOf(item);
	if (index < 0) {
		return false;
	}
	this._items.splice(index, 1);
	return true;
}

Object.defineProperties(ArraySet.prototype, {
	size: {
		get: function() {
			return this._items.length;
		}
	}
});

function notImplemented(fname) {
	throw new Error("ArraySet.prototype." + fname + " is not implemented");
}

ArraySet.prototype.values = function() {
	notImplemented("values");
}

ArraySet.prototype.entries = function() {
	notImplemented("entries");
}

ArraySet.prototype.forEach = function() {
	notImplemented("forEach");
}

module.exports = ArraySet;