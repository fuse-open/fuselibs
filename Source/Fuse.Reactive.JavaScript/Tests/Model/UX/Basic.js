export class Basic {
	constructor() {
		this.isSet = false
	}
	
	get flipped() {
		return !this.isSet
	}
	set flipped(value) {
		this.isSet = !value
	}
}