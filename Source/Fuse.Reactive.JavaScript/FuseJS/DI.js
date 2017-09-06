function createContainer() {
	// Map of dependency names to functions that produce the value to be injected
	var dependencyFactories = new Map();

	function DI(name) {
		if(!dependencyFactories.has(name)) {
			throw new Error("Unable to satisfy dependency '" + name + "'");
		}

		var factory = dependencyFactories.get(name)
		return factory();
	}

	DI.provide = function provide(name, value) {
		if(arguments.length == 1 && typeof name == "object") {
			var deps = name;
			for(var n in deps) {
				provide(n, deps[n]);
			}
		}

		DI.provideTransient(name, function() { return value });
	}
	
	DI.provideTransient = function provideTransient(name, factory) {
		dependencyFactories.set(name, factory);
	}

	DI.provideLazy = function provideLazy(name, factory) {
		var value;
		var hasValue = false;
		DI.provideTransient(name, function() {
			if(!hasValue) {
				value = factory();
				hasValue = true;
			}
			return value;
		});
	}

	DI.wrap = function wrap(func) {
		var argNames = getArgNames(func);
		var wfunc = function() {
			var args = Array.prototype.slice.call(arguments);
			for (var i = 0; i < argNames.length; ++i) {
				var dependency = argNames[i];
				if(args[i] === undefined && dependency !== undefined) {
					args[i] = DI(dependency);
				}
			}
			return func.apply(this, args);
		}
		wfunc.prototype = func.prototype;
		var funcName = func.name.length == 0 ? "<anonymous>" : func.name;
		Object.defineProperty(wfunc, "name", {
			value: funcName + " (DI)",
			writable: false,
			enumerable: false
		})
		return wfunc;
	}

	return DI;
}

function getArgNames(func) {  
    return (func + '')
      .replace(/[/][/].*$/mg,'') // strip single-line comments
      .replace(/\s+/g, '') // strip white space
      .replace(/[/][*][^/*]*[*][/]/g, '') // strip multi-line comments  
      .split('){', 1)[0].replace(/^[^(]*[(]/, '') // extract the parameters  
      .replace(/=[^,]+/g, '') // strip any ES6 defaults  
      .split(',').filter(Boolean); // split & filter [""]
}

var DI = createContainer();
DI.createContainer = createContainer;

module.exports = DI;