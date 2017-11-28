
export default class Async {
	constructor() {
		this.foo = 10;
	}

	doSomething() {
		setTimeout(() => {
			this.foo += 40;
		}, 0);
	}
}