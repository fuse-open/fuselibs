class ModelListOrder {
	constructor() { 
		this.items = [ 2, 3 ]
		
		this._count = 5
	}
	
	add() {
		this.items.push( this._count )
		this._count++
	}

	insert() {
		this.items.splice(1, 0, this._count )
		this._count++
	}
	
	shift() {
		this.items.shift()
	}
}

module.exports = ModelListOrder