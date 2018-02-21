let globalInstanceCount = 0;

export default class {
	constructor(value) {
		this.instanceCount = ++globalInstanceCount;
		this.value = value + "!";
	}
}