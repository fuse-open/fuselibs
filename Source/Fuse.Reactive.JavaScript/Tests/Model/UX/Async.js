
export class Async {
	constructor() {
		this.foo = 10;
	}

	doSomething() {
		console.log("Doing something!")
		setTimeout(() => {
			console.log("I'm in the zone of " + Zone.current.name)
			this.foo += 40;
		}, 0);

		console.log("done Doing something!")
	}
}