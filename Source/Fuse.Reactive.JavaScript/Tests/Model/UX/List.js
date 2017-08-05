class ModelList {
	constructor() { 
		this.items = []
		
		this._count = 5
	}
	
	add() {
		this.items.push( this._count )
		this._count++
	}
	
	shift() {
		this.items.shift()
	}
	
}

module.exports = ModelList