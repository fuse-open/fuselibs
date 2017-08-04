class ModelFunction {
	constructor() {
		this.count = 3
	}
	
	get stars() {
		return "*".repeat( this.count )
	}
	
	incr() {
		this.count++
	}
}

module.exports = ModelFunction