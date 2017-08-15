

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
	if (this.$set instanceof Function) { this.$set.apply(this, arguments); }
}

TreeObservable.add = function() {
	if (this.$add instanceof Function) { this.$add.apply(this, arguments); }
}

TreeObservable.insertAt = function() {
	if (this.$insertAt instanceof Function) { this.$insertAt.apply(this, arguments); }
}

TreeObservable.removeAt = function() {
	if (this.$removeAt instanceof Function) { this.$removeAt.apply(this, arguments); }
}

module.exports = TreeObservable;