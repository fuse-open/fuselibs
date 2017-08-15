export class EmptyList {
	constructor() {
		this.items = [ 1, 2, 3 ];
		this.promisedItems = new Promise(resolve => setTimeout(() => resolve([3, 4, 5]), 0));
	}

	empty() {
		this.items = [];
	}

	emptyPromise() {
		this.promisedItems = new Promise(resolve => setTimeout(() => resolve([]), 0));
	}
}
