function assert(condition) {
	if(!condition) {
		throw new Error("Assertion failed");
	}
}

function isThenable(obj) {
	return "object" === typeof obj
		&& "then" in obj
		&& "function" === typeof obj.then
}

function runTest(fn, self) {
	var result = fn.call(self, assert);

	if(isThenable(result)) {
		result.then(
			function() { console.log("Passed: " + fn.name) },
			function() { console.log("Failed: " + fn.name) }
		);
	}
}

module.exports = function TestBase() {
	var self = this;
	var proto = this;

	while(typeof proto === "object" && proto !== TestBase.prototype) {
		var props = Object.getOwnPropertyNames(proto);
		
		for(var key of props) {
			var test = proto[key];

			if(typeof test === "function" && key !== "constructor") {
				runTest(test, self);
			}
		}
		
		proto = Object.getPrototypeOf(proto);
	}
}