
export default class PromiseTest {
	constructor() {
		this.resolve = () => { throw new Error("Shouldn't happen!"); }
		this.result = new Promise((resolve, reject) => {
			setTimeout(() => {
				resolve("yay!")
			}, 0);
		})
	}

	get somePromise() {
		return new Promise(resolve => setTimeout(function() { resolve("kaka") }, 0))
	}

	changePromise() {
		this.result = new Promise((resolve, reject) => {
			this.resolve = resolve;
		})
	}

	resolveNow() {
		this.resolve("hoho!");
	}
}
