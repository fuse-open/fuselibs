class ModelLoop {
	constructor() {
		this.next = this
		this.value = "%"
		
		this.array = [ 5 ]
		this.array.push( this.array )
	}
}

module.exports = ModelLoop