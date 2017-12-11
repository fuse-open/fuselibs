class Foo {
	constructor(value) {
		this.value = value;
	}
}

export default class {
	constructor() {
		this.list = [ new Foo(1337) ];
		this.field = null;
	}

	step1() {
		this.field = this.list[0];
	}

	step2() {
		this.field = new Foo(0);
	}

	step3() {
		this.list.push(new Foo(123));
	}
}