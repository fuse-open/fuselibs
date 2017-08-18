class Inner {
	constructor(v) {
		this.value = v
	}
	
	set(v) {
		this.value = v
	}
}

export class Nested {
	constructor() { 
		this.a = new Inner(1)
		this.b = new Inner(2)
		this.c = this.b
	}
	
	modB() {
		this.b.set(3)
	}
	
	repC() {
		this.c = this.a
	}
}