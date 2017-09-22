

/* 
	This function represents the low-level interface between the TreeObservable mechanism
	on the Uno side, and JS. When an instance of TreeObservable is found in the data context,
	the Uno side instruments the object to allow change callbacks to Uno.

	This class offers a set of static methods as public API for manipulating the datacontext.
	JS code should use this API instead of the instrumented entrypoints directly, as those
	are subject to change.
 */
function TreeObservable()
{
}

TreeObservable.set = function() {
	if (this.__fuse_set instanceof Function) { this.__fuse_set.apply(this, arguments); }
}

TreeObservable.add = function() {
	if (this.__fuse_add instanceof Function) { this.__fuse_add.apply(this, arguments); }
}

TreeObservable.insertAt = function() {
	if (this.__fuse_insertAt instanceof Function) { this.__fuse_insertAt.apply(this, arguments); }
}

TreeObservable.removeAt = function() {
	if (this.__fuse_removeAt instanceof Function) { this.__fuse_removeAt.apply(this, arguments); }
}

module.exports = TreeObservable;