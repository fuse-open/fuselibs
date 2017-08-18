class Item {
	constructor( name ) {
		this.name = name
	}
}

class ModelEach {
	constructor() {
		this.simple = [ "one", "two", "three" ]
		this.items = [ "one", "two", "three" ].map( n => new Item(n) )
	}
}

module.exports = ModelEach