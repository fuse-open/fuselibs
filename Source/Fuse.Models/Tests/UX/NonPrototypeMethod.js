export default class NonPrototypeMethod
{
	constructor() {
		this.value = 0;
		this.increment = function() {
			this.value++;
		}
	}
}