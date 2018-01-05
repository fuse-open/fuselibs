class Cycle {
	constructor() {
		this.itself = this;
		this.data = "foo";
	}
}

let globalCycle = new Cycle();

export default class Root {
	constructor() {
		this.attachCycle();
	}

	detachCycle() {
		this.cycle = null;
	}

	attachCycle() {
		this.cycle = globalCycle;
	}

	changeCycleData() {
		this.cycle.data = "bar";
	}
}