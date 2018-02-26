export default class Inner {
	constructor(id, onNewInnerInstance) {
		this.message = `(${id})`;
		onNewInnerInstance();
	}
}