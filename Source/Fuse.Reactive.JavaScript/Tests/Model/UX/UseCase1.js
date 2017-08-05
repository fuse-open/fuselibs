class Item {
	constructor( name ) {
		this.name = name
	}
}

class UseCase1 {
	constructor() {
		this.items = [ "one", "two", "three", "four", "five" ].map( n => new Item(n) )
		this.sel = []
	}

	add(args) {
		//this.sel.push(
	}
	
	remove(args) {
	}
}

module.exports = UseCase1