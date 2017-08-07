class Item {
	constructor( name ) {
		this.name = name
	}
}

class UseCase1 {
	constructor() {
		this.items = [ "one", "two", "three", "four", "five" ].map( n => new Item(n) )
		this.sel = [ this.items[4] ]
	}

	add(args) {
		console.log(this.items[1].$id + " : " + this.items[1].name)
		console.log(args.data.$id + " : " + args.data.name)
		this.sel.push(args.data)
	}
	
	remove(args) {
		console.log(this.items[4].$id + " : " + this.items[4].name)
		console.log(args.data.$id +  " : " + args.data.name )
		
		console.log( this.sel.indexOf(args.data) )
		this.sel.splice( this.sel.indexOf(args.data), 1 )
	}
}

module.exports = UseCase1