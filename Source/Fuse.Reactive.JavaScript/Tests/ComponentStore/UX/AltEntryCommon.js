class Inner {
	constructor() {
		this.value = "a"
	}
	
	set(v) {
		this.value = v
	}
}

exports.item = new Inner()
