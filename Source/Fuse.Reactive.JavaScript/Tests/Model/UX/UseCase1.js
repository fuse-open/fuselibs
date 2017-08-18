class Item {
	constructor( name ) {
		this.name = name
	}
}

export class UseCase1 {
	constructor() {
		this.items = [ "one", "two", "three", "four", "five" ].map( n => new Item(n) )
		this.sel = [ this.items[4] ]
	}

	add(args) {
		this.sel.push(args.data)
	}
	
	remove(args) {
		this.sel.splice( this.sel.indexOf(args.data), 1 )
	}
}