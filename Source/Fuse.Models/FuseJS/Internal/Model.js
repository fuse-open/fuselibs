var TreeObservable = require("FuseJS/TreeObservable")

require("Polyfills/Window");
require("./zone.min")
require("./ZonePatches");

var rootZone = Zone.current;

function shouldEmitProperty(key) {
	return !key.startsWith("__fuse_");
}

function isThenable(thing) {
	return thing instanceof Object
		&& typeof thing.then === "function";
}

function Model(initialState, stateInitializer)
{
	var stateToMeta = new Map();
	var idToMeta = new Map();
	var evaluatingDerivedProps = 0;
	var idEnumerator = 0;
	var store = this;

	instrument(null, this, initialState, stateInitializer)

	function instrument(parentMeta, node, state, stateInitializer)
	{
		if (stateInitializer instanceof Function) {
			runInZone(stateInitializer);
		}

		var meta = stateToMeta.get(state);

		if (meta instanceof Object) {
			if (parentMeta !== null) { meta.parents.push(parentMeta); }
			return meta.node;
		}

		meta = {
			parents: [parentMeta],
			id: idEnumerator++,
			node: node,
			state: state,
			promises: {},
			isClass: false
		}
		
		idToMeta.set(meta.id, meta);
		stateToMeta.set(state, meta);
		node.__fuse_id = meta.id;
		node.__fuse_raw = state;

		//this is an internal variable but needs to be emitted for use in Uno, the primary use-case is for
		//the default $path for Navigation. Ideally this wouldn't be part of the IObject keys, but it works for now.
		if (state instanceof Object && !('$__fuse_classname' in state)) {
			node.$__fuse_classname = state.constructor.name;
		}

		// create zone lazily to avoid overhead when not needed
		var nodeZone = undefined;
		function prepareZone() {
			if (nodeZone != undefined) { return; }
			nodeZone = rootZone.fork({
				name: (parentMeta != null ? parentMeta.key : '(root)'),
				onInvokeTask: function(parentZoneDelegate, currentZone, targetZone, task, applyThis, applyArgs) {
					dirty();
					parentZoneDelegate.invokeTask(targetZone, task, applyThis, applyArgs);
				},
				onHandleError: function(error) {
					throw error;
				}
			})
		}

		meta.isClass = false;
		for (var k in state) {
			if (!shouldEmitProperty(k)) continue;
			var v = state[k];
			if (v instanceof Function) {
				node[k] = wrapFunction(v);
				state[k] = node[k];
				meta.isClass = true;
			}
			else if (isThenable(v)) {
				node[k] = null;
				dealWithPromise(k, v);
			}
			else if (v instanceof Array) {
				node[k] = instrument({meta: meta, key: k}, [], v);
			}
			else if (v instanceof Object) {
				node[k] = instrument({meta: meta, key: k}, {}, v);
			}
			else
			{
				node[k] = v;
			}
		}

		var propGetters = {}

		if (!(state instanceof Array)) {
			registerProps(state);
		}

		function dealWithPromise(key, prom) {
			if (meta.promises[key] !== prom) {
				meta.promises[key] = prom;
				prom.then(function(result) {
					if (meta.promises[key] === prom) {
						removeAsParentFrom(node[key])
						set(key, wrap(key, result));
					}
				})
			}
		}

		function registerProps(obj) {

			var keys = Object.getOwnPropertyNames(obj);
			for (var i in keys) {
				var p = keys[i];
				if (p === "constructor") { continue; }
				try {
					var value = state[p];
				}
				catch(e) {
					continue;
				}

				if (value instanceof Function) {
					node[p] = wrapFunction(value);
					state[p] = node[p];
				}
				else {
					var descriptor = Object.getOwnPropertyDescriptor(obj, p);
					if (descriptor.get instanceof Function)
					{
						if (isThenable(value)) { node[p] = null; dealWithPromise(p, value); }
						else { node[p] = wrap(p, value); }
						propGetters[p] = descriptor.get;
					}
				}
			}

			// Include members from object's prototype chain (to allow ES6 classes)
			var proto = Object.getPrototypeOf(obj);
			if (proto && proto !== Object.prototype) { registerProps(proto); }
		}

		function hasParent() {
			return meta.parents.length > 0;
		}
		
		meta.evaluateDerivedProps = function(visited)
		{
			if (!hasParent()) return;

			isDerivedPropsDirty = false;

			if (visited.indexOf(node) !== -1) { return; }
			visited.push(node);

			for (var p in propGetters) {
				evaluatingDerivedProps++;
				try
				{
					var v = propGetters[p].call(state);
					if (isThenable(v)) {
						dealWithPromise(p, v);
					}
					else {
						set(p, wrap(p, v), true); // don't count this as a state change
					}
				}
				finally
				{
					evaluatingDerivedProps--;
				}
			}
			
			for (var parent of meta.parents) {
				if (parent !== null) {
					parent.meta.evaluateDerivedProps(visited);
				}
			}
		}

		function runInZone(func) {
			prepareZone();
			return nodeZone.run(func);
		}

		function wrapFunction(func) {
			var f = function() {
				var args = arguments;
				return runInZone(function() {
					dirty();
					return func.apply(state, args);
				});
			}
			f.__fuse_isWrapped = true;
			return f;
		}

		var isDirty = false;

		function dirty() {
			if (evaluatingDerivedProps !== 0) { return; }
			if (isDirty) { return; }
			isDirty = true;
			rootZone.run(function() {
				setTimeout(function() {
					meta.diff(new Set())
				}, 0)
			});
		}

		var changesDetected = 0;

		meta.diff = function(visited) {
			if (!(visited instanceof Set)) {
				throw new Error("Needs set of visited nodes");
			}
			if (visited.has(state)) {
				return;
			}
			visited.add(state);

			isDirty = false;

			if (!hasParent()) {
				// This object is no longer attached to the model tree,
				// we got this callback as an async remnant
				return; 
			}

			if (state instanceof Array) {
				for (var i = 0; i < Math.min(state.length, node.length); i++) { 
					if (isThenable(state[i])) { dealWithPromise(i, state[i]); }
					if (oldValueEquals(i, state[i])) continue;
					
					if (state.length > node.length) {
						insertAt(i, state[i]);
						i++;
					}
					else if (state.length < node.length) {
						removeRange(i, 1)
						i--;
					}
					else {
						removeAsParentFrom(node[i]);
						set(i, wrap(i, state[i]))
					}
				}
				
				if (state.length > node.length) { 
					addRange(state.slice(node.length, state.length))
				}
				else if (state.length < node.length) {
					removeRange(i, node.length-state.length) 
				}
			}
			else {
				for (var k in state) {
					if (!shouldEmitProperty(k)) continue;
					var v = state[k];
					update(k, v, visited);
				}
			}

			if (changesDetected > 0) {
				dirtyDerivedProps()
				changesDetected = 0
			}
		}

		var isDerivedPropsDirty = false;
		function dirtyDerivedProps() {
			if (isDerivedPropsDirty) { return; }
			isDerivedPropsDirty = true;
			rootZone.run(function() {
				setTimeout(function() { meta.evaluateDerivedProps([]) }, 0)
			});
		}

		function oldValueEquals(key, newValue) {
			if (newValue instanceof Object) {
				var keyMeta = stateToMeta.get(newValue);
				return keyMeta instanceof Object && meta.node[key].__fuse_id === keyMeta.id;
			}
			else {
				return node[key] === newValue;
			}
		}

		function removeAsParentFrom(node) {
			if (!(node instanceof Object)) { return; }
			var oldMeta = idToMeta.get(node.__fuse_id);
			if (oldMeta instanceof Object) {
				var thisIndex = oldMeta.parents.findIndex(function(x) { return x.meta == meta });
				oldMeta.parents.splice(thisIndex, 1);
				oldMeta.invalidatePath();

				if (oldMeta.parents.length === 0) {
					idToMeta.delete(node.__fuse_id);
					stateToMeta.delete(oldMeta.state);
				}
			}
		}

		if (node instanceof Array) {
			node.__fuse_replaceAll = function(values) {
				replaceAllInternal(state, values);
				replaceAllInternal(node, values);
				dirty();
			}
		}

		function replaceAllInternal(subject, values) {
			Array.prototype.splice.call(subject, 0);
			Array.prototype.push.apply(subject, values);
		}

		node.__fuse_requestChange = function(key, value) {
			var changeAccepted = true;
			if ('$requestChange' in state) {
				changeAccepted = state.$requestChange(key, value);
			}

			if (changeAccepted) {
				state[key] = value;
				setInternal(meta.getPath(), key, value);
			}

			meta.diff(new Set());
		}

		function update(key, value, visited)
		{
			if (value instanceof Function) {
				if (!value.__fuse_isWrapped) {
					state[key] = wrapFunction(value)
					set(key, state[key]);
				}
			}
			else if (isThenable(value)) {
				dealWithPromise(key, value);
			}
			else if (value instanceof Object) {
				var keyMeta = stateToMeta.get(value);
				var oldValue = meta.node[key];

				var newValue;
				if (keyMeta instanceof Object) {
					// Value is already instrumented
					newValue = keyMeta.node;
				}
				else if (value instanceof Object) {
					newValue = instrument({meta: meta, key: key}, (value instanceof Array) ? [] : {}, value);
				}
				else {
					newValue = value;
				}

				if (oldValue instanceof Object &&
					keyMeta instanceof Object &&
					oldValue.__fuse_id === keyMeta.id
				)
				{
					if (!keyMeta.isClass) { 
						keyMeta.diff(visited);
					}
				}
				else {
					removeAsParentFrom(oldValue);
					set(key, newValue);
				}
			}
			else if (value !== node[key])
			{
				set(key, value);
			}
		}

		var cachedPath = null;
		function getPath() {
			if (cachedPath === null) { cachedPath = computePath(); }
			return cachedPath;
		} 
		
		meta.getPath = getPath;
		meta.invalidatePath = function() { cachedPath = null; }

		// Finds a valid path to the root TreeObservable, if any
		function computePath()
		{
			for (var i = 0; i < meta.parents.length; i++) {
				if (meta.parents[i] === null) { return [] }
				else 
				{
					var arr = meta.parents[i].meta.getPath();
					if (arr instanceof Array) {
						return arr.concat(meta.parents[i].key);
					}	
				}
			}
		}

		function set(key, value, omitStateChange)
		{
			var path = getPath();
			if (!setInternal(path, key, value, omitStateChange)) { return; }

			var argPath = path.concat(key, value instanceof Array ? [value] : value);
			TreeObservable.set.apply(store, argPath);
		}

		function removeRange(index, count) {
			for (var i = 0; i < count; i++) {
				removeAsParentFrom(node[index+i]);
			}
			node.splice(index, count);
			var removePath = getPath().concat(index);
			for (var i = 0; i < count; i++) {
				TreeObservable.removeAt.apply(store, removePath);
			}
			changesDetected++;
		}

		function wrap(key, item) {
			if (isThenable(item)) {
				dealWithPromise(key, item);
			}
			else if (item instanceof Array) {
				return instrument({meta: meta, key: key}, [], item)
			}
			else if (item instanceof Object) {
				return instrument({meta: meta, key: key}, {}, item)
			}
			else {
				return item
			}
		}

		function insertAt(index, item) {
			node.splice(index, 0, null);
			node[index] = item = wrap(index, item)
			
			TreeObservable.insertAt.apply(store, getPath().concat(index, item));
			changesDetected++;
		}

		function addRange(items) {
			for (var item of items) {
				var index = node.length;
				node.push(null);
				node[index] = item = wrap(index, item);
				TreeObservable.add.apply(store, getPath().concat(item));
			}
			
			changesDetected++;
		}
		
		function pathString(key) {
			var path = getPath();
			if (path.length === 0) { return key }
			if (path.length === 1) { return path[0] + "." + key; }
			return path.concat(key).join(".");
		}

		function setInternal(path, key, value, omitStateChange) {
			if (node[key] === value) { return false; }
			node[key] = value;

			if (!omitStateChange) { changesDetected++; }

			return true;
		}

		return node;
	}
}

Model.prototype = Object.create(TreeObservable.prototype);

module.exports = Model;
