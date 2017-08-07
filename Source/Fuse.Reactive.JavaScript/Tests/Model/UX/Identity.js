class Item {
	constructor( name ) {
		this.name = name
	}
}

class Identity {
	constructor() {
		this.items = [ new Item("one"), new Item("two") ]
		this.foo = [ this.items[0] ]
		this.bar = [ this.items[1] ]
	}
	
	get items0id() {
		console.log( "ID:" + this.items[0].$id +  " :: " + this.items[0].name )
		return this.items[0].$id
	}
	get foo0id() {
		return this.foo[0].$id
	}
}

module.exports = Identity