var instCount = 0

class ModelBind {
	constructor(v) {
		this.id = instCount++
		this.value = v
	}
}

module.exports = ModelBind