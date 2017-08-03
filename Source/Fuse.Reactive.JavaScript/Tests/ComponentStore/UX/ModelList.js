class ModelList {
	constructor() { 
		this.items = []
		
		this._count = 5
	}
	
	add() {
		console.log( "Adding" )
		this.items.push( this._count )
		this._count++
	}
}

module.exports = ModelList