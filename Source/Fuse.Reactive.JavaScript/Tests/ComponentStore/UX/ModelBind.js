var instCount = 0

class ModelBind {
	constructor(v) {
		this.id = instCount++
		this.value = v
		this.load = 5
	}
	
	incrLoad() {
		this.load++
	}
}

module.exports = ModelBind