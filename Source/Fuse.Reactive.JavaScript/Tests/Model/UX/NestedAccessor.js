class Inner {
	constructor() {
		this.value = 10
	}
	
	incr() {
		this.value++
	}
	
	negCount() {
		return -this.value
	}
}

export class NestedAccessor {
	constructor() {
		this.inner = new Inner()
	}

	get value() {
		return this.inner.value
	}
	
	get highCount() {
		return this.inner.value + 100
	}
	set highCount(v) {
		this.inner.value = v - 100
	}
	
	get negCount() {
		return this.inner.negCount()
	}
	
	incr() {
		this.inner.incr()
	}
}