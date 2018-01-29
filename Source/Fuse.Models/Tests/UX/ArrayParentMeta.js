export default class {
	constructor() {
		this.array = [
			{ str: "foo" },
			{ str: "bar" },
			{ str: "baz" }
		];
	}

	step1() {
		this.array.splice(1, 1);
	}

	step2() {
		this.array[0] = { str: "baz" };
	}
}