function assert(condition) {
	if(!condition) {
		throw new Error("Assertion failed");
	}
}

module.exports = function Test() {
	var props = Object.getOwnPropertyNames(Object.getPrototypeOf(this));
	for(var prop of props) {
		console.log(prop);
		var test = this[prop];
		if(!(test instanceof Function) || prop === "constructor") {
			continue;
		}

		(function(prop) {
			var result = test.call(this, assert);
			if("then" in result && result.then instanceof Function) {
				result.then(
					() => console.log("Passed: " + prop),
					() => console.log("Failed: " + prop));
			}
		})(prop);
	}
}