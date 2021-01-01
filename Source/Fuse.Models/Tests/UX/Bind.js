var instCount = 0

export default class Bind {
	constructor(view) {
		this.id = instCount++
		this.Load = 5
		this.DefaultFromJS = 10
		this.Value = undefined
	}

	incrLoad() {
		this.Load++
	}

	get value() { return this.Value; }
}