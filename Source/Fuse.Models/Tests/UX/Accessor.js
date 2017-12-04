export default class ModelAccessor {
	constructor() {
		this.value = 10
	}

	get highCount() {
		return this.value + 100
	}
	set highCount(v) {
		this.value = v - 100
	}
	
	get doubleHigh() {
		return this.highCount * 2
	}
	
	incr() {
		this.value++
	}
}
