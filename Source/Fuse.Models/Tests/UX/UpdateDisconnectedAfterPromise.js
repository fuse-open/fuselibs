
class Thing {
	constructor() {
		this.resolvePromise = () => { throw new Error("resolvePromise was called before promise was created") };
		this.promise = new Promise(resolve => {
			this.resolvePromise = () => resolve("foo");
		});
	}
}

let throwFromGetter = false;
let disconnectedThing = new Thing();

export default class {
	constructor() {
		this.thing = disconnectedThing;
		this.resolvePromise = () => disconnectedThing.resolvePromise();
	}

	connect() {
		this.thing = disconnectedThing;
	}

	disconnect() {
		this.thing = null;
	}
}