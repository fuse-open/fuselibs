class Inner {
	constructor(v) {
		this.value = v
	}
	
	incr() {
		this.value++
	}
}

var cur = new Inner(5)
var next = new Inner(10)

export class Disconnected {
	constructor() {
		this.inner = cur
	}
	
	updateNext() {
		next.incr()
	}
	
	swap() {
		var t = cur
		cur = next
		next = t
		this.inner = cur
	}
}