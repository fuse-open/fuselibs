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
	
	replace() {
		this.items = [ 4, 8, 2, 5, 1 ]
	}
	
	sort() {
		this.items.sort( function(a,b) { return a - b } )
	}
}

module.exports = ModelList