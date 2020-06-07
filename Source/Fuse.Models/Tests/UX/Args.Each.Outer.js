let globalOuterInstanceCount = 0;

export default class Outer {
	constructor() {
		this.items = [
			{ id: "foo" },
			{ id: "bar" },
			{ id: "baz" },
		];

		this.outerInstanceCount = ++globalOuterInstanceCount;
		this.innerInstanceCount = 0;
	}

	onNewInnerInstance() {
		this.innerInstanceCount++;
	}
}