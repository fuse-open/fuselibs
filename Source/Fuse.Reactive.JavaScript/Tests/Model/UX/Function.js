export class Function {
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
