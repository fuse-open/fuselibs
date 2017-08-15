var TreeObservable = require("FuseJS/TreeObservable")

function Model(source)
{
	var stateToMeta = new Map();
	var idToMeta = new Map();
	var evaluatingDerivedProps = 0;
	var idEnumerator = 0;
	var store = this;

	instrument(null, this, source)

	function instrument(parentMeta, node, state)
	{
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
		node.$id = meta.id;
		node.$raw = state;

		if (state instanceof Object) {
			node.$template = state.constructor.name;
		}

		meta.isClass = false;
		for (var k in state) {
			if (k.startsWith("$")) continue;
			var v = state[k];
			if (v instanceof Function) {
				node[k] = wrapFunction(k, v);
				state[k] = node[k];
				meta.isClass = true;
			}
			else if (v instanceof Promise) {
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
						set(key, result);
					}
				})
			}
		}

		function registerProps(obj) {

			var descs = Object.getOwnPropertyDescriptors(obj);
			for (var p in descs) {
				if (p === "constructor") { continue; }
				var value = state[p];
				if (value instanceof Function) {
					node[p] = wrapFunction(p, value);
					state[p] = node[p];
				}
				else if (descs[p].get instanceof Function)
				{
					if (value instanceof Promise) { node[p] = null; dealWithPromise(p, value); }
					else { node[p] = value; }
					propGetters[p] = descs[p].get;
				}
			}

			// Include members from object's prototype chain (to allow ES6 classes)
			var proto = Object.getPrototypeOf(obj);
			if (proto && proto !== Object.prototype) { registerProps(proto); }
		}
		
		meta.evaluateDerivedProps = function(visited)
		{
			if (visited.indexOf(node) !== -1) { return; }
			visited.push(node);

			for (var p in propGetters) {
				evaluatingDerivedProps++;
				try
				{
					var v = propGetters[p].call(state);
					if (v instanceof Promise) {
						dealWithPromise(p, v);
					}
					else {
						set(p, v);
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

		function wrapFunction(name, func) {

			var f = function() {
				var res = func.apply(state, arguments);
				
				if (evaluatingDerivedProps === 0) {
					dirty();
				}
				return res
			}
			f.$isWrapped = true;

			return f;
		}

		var isDirty = false;

		function dirty() {
			if (isDirty) { return; }
			isDirty = true;
			setTimeout(meta.diff, 0);
		}

		var changesDetected = 0;

		meta.diff = function() {
			isDirty = false;

			if (meta.parents.length === 0) { 
				// This object is no longer attached to the model tree,
				// we got this callback as an async remnant
				return; 
			}

			if (state instanceof Array) {
				for (var i = 0; i < Math.min(state.length, node.length); i++) { 
					if (state[i] instanceof Promise) { dealWithPromise(i, state[i]); }
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
						set(i, state[i]);
					}
				}
				
				if (state.length > node.length) { 
					addRange(state.slice(node.length, state.length))
				}
				else {
					removeRange(i, node.length-state.length) 
				}
			}
			else {
				for (var k in state) {
					if (k.startsWith("$")) continue;
					var v = state[k];
					update(k, v);
				}
			}

			if (changesDetected > 0) {
				meta.evaluateDerivedProps([]); 
				changesDetected = 0;
			}
		}

		function oldValueEquals(key, newValue) {
			if (newValue instanceof Array) {
				var keyMeta = stateToMeta.get(newValue);
				return keyMeta instanceof Object && meta.node[key].$id === keyMeta.id;
			}
			else if (newValue instanceof Object) {
				var keyMeta = stateToMeta.get(newValue);
				return keyMeta instanceof Object && meta.node[key].$id === keyMeta.id;
			}
			else {
				return node[key] === newValue;
			}
		}

		function removeAsParentFrom(node) {
			var oldMeta = idToMeta.get(node.$id);
			if (oldMeta instanceof Object) {
				var thisIndex = oldMeta.parents.findIndex(function(x) { return x.meta == meta });
				oldMeta.parents.splice(thisIndex, 1);
				oldMeta.invalidatePath();

				if (oldMeta.parents.length === 0) {
					idToMeta.delete(node.$id);
					stateToMeta.delete(oldMeta.state);
				}
			}
		}

		node.$requestChange = function(key, value) {
			var changeAccepted = true;
			if ('$requestChange' in state) {
				changeAccepted = state.$requestChange(key, value);
			}

			if (changeAccepted) {
				state[key] = value;
				setInternal(meta.getPath(), key, value);
			}

			meta.diff();
		}

		function update(key, value)
		{
			if (value instanceof Function) {
				if (!value.$isWrapped) {
					state[key] = wrapFunction(k, value)
					set(key, state[key]);
				}
			}
			else if (value instanceof Promise) {
				dealWithPromise(key, value);
			}
			else if (value instanceof Array) {
				var keyMeta = stateToMeta.get(value);

				if (keyMeta instanceof Object && meta.node[key].$id == keyMeta.id) 
				{ 
					if (!keyMeta.isClass) { 
						keyMeta.diff(); 
					}
				}
				else 
				{ 
					removeAsParentFrom(node[key]);
					set(key, instrument({meta: meta, key: key}, [], value)); 
				}
			}
			else if (value instanceof Object) {
				var keyMeta = stateToMeta.get(value);

				if (keyMeta instanceof Object && meta.node[key].$id === keyMeta.id) {
					if (!keyMeta.isClass) {
						keyMeta.diff();
					}
				}
				else { 
					removeAsParentFrom(node[key]);
					set(key, instrument({meta: meta, key: key}, {}, value));  
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

		function set(key, value)
		{
			var path = getPath();
			if (!setInternal(path, key, value)) { return; }

			var argPath = path.concat(key, value instanceof Array ? [value] : value);
			TreeObservable.set.apply(store, argPath);
		}

		function removeRange(index, count) {
			node.splice(index, count);
			var removePath = getPath().concat(index);
			for (var i = 0; i < count; i++) {
				TreeObservable.removeAt.apply(store, removePath);
			}
			changesDetected++;
		}

		function insertAt(index, item) {
			node.splice(index, 0, item);
			TreeObservable.insertAt.apply(store, getPath().concat(index, item));
			changesDetected++;
		}

		function addRange(items) {
			for (var item of items) {
				node.push(item);
				TreeObservable.add.apply(store, getPath().concat(item));
			}
			
			changesDetected++;
		}
		
		function pathString(key) {
			var path = getPath();
			if (path.length === 0) { return key }
			if (path.length === 1) { return path[0] + "." + key; }
			return path.reduce((a, b) => a + "." + b) + "." + key;
		}

		function setInternal(path, key, value) {
			if (node[key] === value) { return false; }
			node[key] = value;

			var msg = {
				operation: "set",
				path: path,
				key: key,
				value: value
			}

			changesDetected++;

			return true;
		}

		return node;
	}
}

Model.prototype = Object.create(TreeObservable.prototype);

module.exports = Model;
