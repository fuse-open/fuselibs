class Flights {
	constructor(app) {
		this.app = app
		this.pageIndex = 5
		//TODO: Shouldn't be required (Path can default to ClassName)
		this.$path = "Flights"
	}
}

class Home {
	constructor(app) {
		this.app = app
		
		this.homePages = [
			new Flights(this.app),
		]
		
		this.pageIndex = 0
	}
}

export default class Loop2 {
	constructor() {
		this.home = new Home(this)
		
		this.pages = [
			this.home
		]
	}
}
