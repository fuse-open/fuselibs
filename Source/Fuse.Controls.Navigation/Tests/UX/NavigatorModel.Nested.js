class InnerPage {
	constructor() {
		this.title = "inner"
	}
}

class SomePage {
	constructor() {
		this.innerPages = [new InnerPage()]
		this.title = "outer"
	}
}

export default class Nested {
	constructor() {
		this.pages = [new SomePage()];
	}
}
