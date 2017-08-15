var instCount = 0

class ModelBind {
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

module.exports = ModelBind