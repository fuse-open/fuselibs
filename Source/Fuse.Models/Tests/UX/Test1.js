export default class TestClass {
	constructor() {
		this.isSet = false;
	}

	get flipped() {
		return !this.isSet;
	}
	set flipped(value) {
		this.isSet = !value;
	}
}