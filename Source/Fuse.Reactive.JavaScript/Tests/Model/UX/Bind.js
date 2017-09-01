var instCount = 0

export class Bind {
	constructor(view) {
		this.id = instCount++
		this.view = view;
		this.view.Load = 5
	}
	
	incrLoad() {
		this.view.Load++
	}

	get value() { return this.view.Value; }
}