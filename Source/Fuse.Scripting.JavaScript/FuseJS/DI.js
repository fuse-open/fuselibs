function createContainer() {
	var provider = undefined;

	function resolve(dependency) {
		if(provider === undefined) {
			throw new Error("Requested dependency '" + dependency + "', but no provider has been configured");
		}

		if(dependency in provider) {
			return provider[dependency];
		}

		throw new Error("Unable to satisfy dependency '" + dependency + "'");
	}

	function DI(thing) {
		if(thing instanceof Object) {
			provider = thing;
		}
		else if("string" == typeof thing) {
			return resolve(thing);
		}
		else {
			throw new Error("DI(...): Expected provider object or dependency name, got '" + thing + "'");
		}
	}

	return DI;
}

var GlobalDI = createContainer();
GlobalDI.createContainer = createContainer;

module.exports = GlobalDI;