class Inner {
	constructor() {
		this.value = "a"
	}
	
	set(v) {
		this.value = v
	}
}

export var item = new Inner()
