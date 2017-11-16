class Item {
	constructor( name ) {
		this.name = name
	}
}

export class Each {
	constructor() {
		this.simple = [ "one", "two", "three" ]
		this.items = [ "one", "two", "three" ].map( n => new Item(n) )
	}
}