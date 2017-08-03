class ModelList {
	constructor() { 
		this.items = []
		
		this._count = 0
	}
	
	add() {
		console.log( "Adding" )
		this.items.push( this._count )
		this._count++
	}
}

module.exports = ModelList