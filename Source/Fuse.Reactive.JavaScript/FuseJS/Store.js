
var TreeObservable = require("FuseJS/TreeObservable")

function Store(state)
{
	if (!(this instanceof Store)) { return new Store(state); }

	var store = this;

	var api = 
	{
		get : function() {
			return store;
		},
		set : function() 
		{
			var obj = walk(store, arguments, 0, 2);
			obj[arguments[arguments.length-2]] = arguments[arguments.length-1];
			if (store.$set instanceof Function) { store.$set.apply(null, arguments); }
		},
		add: function() 
		{
			var obj = walk(store, arguments, 0, 1);
			obj.push(arguments[arguments.length-1]);
			if (store.$add instanceof Function) { store.$add.apply(null, arguments); }
		},
		removeAt: function() 
		{
			var obj = walk(store, arguments, 0, 1);
			obj.splice(arguments[arguments.length-1], 1);
			if (store.$removeAt instanceof Function) { store.$removeAt.apply(null, arguments); }
		},
		insertAt: function() 
		{
			var obj = walk(store, arguments, 0, 2);
			obj.splice(arguments[arguments.length-2], 0, arguments[arguments.length-1]);
			if (store.$insertAt instanceof Function) { store.$insertAt.apply(null, arguments); }
		}
	}

	function funcWrapper(func) {
		return function() {
			func.apply(api, arguments);
		}
	}

	for (var k in state) {
		var value = state[k];
		if (value instanceof Function) {
			value = funcWrapper(value);
		}
		store[k] = value;
	}
}

function walk(obj, path, pos, limit)
{
	while (pos < path.length - limit)
	{
		var key = path[pos++];
		obj = obj[key];
	}
	return obj;
}

Store.prototype = Object.create(TreeObservable.prototype);


module.exports = Store;