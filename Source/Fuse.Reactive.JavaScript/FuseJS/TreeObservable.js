

/* 
	This function represents the low-level interface between the TreeObservable mechanism
	on the Uno side, and JS. When an instance of TreeObservable is found in the data context,
	the Uno side injects entrypoints to the object to allow change callbacks to Uno, 
	as seen i Fuse.Reactive.TreeObservable.Subscribe.

	This class doesn't offer any public APIs. Users are intended to use subclasses that
	offer a more JS-friendly API, like FuseJS/Store
 */
function TreeObservable()
{
}

module.exports = TreeObservable;