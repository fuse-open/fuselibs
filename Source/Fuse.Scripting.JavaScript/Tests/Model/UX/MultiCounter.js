import Counter from "./MultiCounter_Counter"

export class MultiCounter {
	constructor() {
		this.counters = [ new Counter() ];
	}

	addCounter() {
		this.counters.push(new Counter());
	}

	removeCounter() {
		this.counters.pop();
	}
};
