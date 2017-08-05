

var TreeObservable = require("FuseJS/TreeObservable")

function ComponentStore(source)
{
	var stateToMeta = new Map();

	var idEnumerator = 0;
	var store = this;
	instrument(null, this, [], source)

	var subscribers = []

	var evaluatingDerivedProps = 0;

	this.subscribe = function(callback) {
		subscribers.push(callback);
	}

	function instrument(parentMeta, node, path, state)
	{
		var meta = stateToMeta.get(state);

		if (meta instanceof Object) {
			if (parentMeta !== null) { meta.parents.push(parentMeta); }
			return meta.node;
		}

		meta = {
			parents: parentMeta !== null ? [parentMeta] : [],
			id: idEnumerator++,
			node: node,
			state: state,
			isClass: false
		}
		stateToMeta.set(state, meta);

		node.$id = meta.id;

		meta.isClass = false;
		for (var k in state) {
			if (k.startsWith("$")) continue;
			var v = state[k];
			if (v instanceof Function) {
				node[k] = wrapFunction(k, v);
				state[k] = node[k];
				meta.isClass = true;
			}
			else if (v instanceof Array) {
				node[k] = instrument(meta, [], path.concat(k), v);
			}
			else if (v instanceof Object) {
				node[k] = instrument(meta, {}, path.concat(k), v);
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
					node[p] = value;
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
					set(p, v);
				}
				finally
				{
					evaluatingDerivedProps--;
				}
			}
			
			for (var parent of meta.parents) {
				parent.evaluateDerivedProps(visited);
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
			if (state instanceof Array) {
				var c = Math.min(state.length, node.length);
				for (var i = 0; i < c; i++) { 
					 update(i, state[i]); 
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

		node.$requestChange = function(key, value) {
			var changeAccepted = true;
			if ('$requestChange' in state) {
				changeAccepted = state.$requestChange(key, value);
			}

			if (changeAccepted) {
				state[key] = value;
				setInternal(key, value);
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
					set(key, instrument(meta, [], path.concat(key), value)); 
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
					set(key, instrument(meta, {}, path.concat(key), value));  
				}
			}
			else if (value !== node[key])
			{
				set(key, value);
			}
		}

		function set(key, value)
		{
			if (!setInternal(key, value)) { return; }

			var argPath = path.concat(key, value instanceof Array ? [value] : value);
			TreeObservable.set.apply(store, argPath);
		}

		function removeRange(index, count) {
			node.splice(index, count);
			var removePath = path.concat(index);
			for (var i = 0; i < count; i++) {
				TreeObservable.removeAt.apply(store, removePath);
			}
			changesDetected++;
		}

		function addRange(items) {
			for (var item of items) {
				node.push(item);
				TreeObservable.add.apply(store, path.concat(item));
			}
			
			changesDetected++;
		}
		
		function pathString(key) {
			if (path.length === 0) { return key }
			if (path.length === 1) { return path[0] + "." + key; }
			return path.reduce((a, b) => a + "." + b) + "." + key;
		}

		function setInternal(key, value) {
			if (node[key] === value) { return false; }
			node[key] = value;

			var msg = {
				operation: "set",
				path: path,
				key: key,
				value: value
			}

			changesDetected++;

			for (var s of subscribers) s.call(store, msg);
			return true;
		}

		return node;
	}
}

ComponentStore.prototype = Object.create(TreeObservable.prototype);

module.exports = ComponentStore;