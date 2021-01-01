class LeftPage {
	constructor() {
		this.$path = "left";
		this.title = "Left"
	}
}

class RightPage {
	constructor() {
		this.title = "Right"
	}
}

class MainPage {
	constructor() {
		this.$path = "main"
		this.title = "Main"
	}
}

export default class State {
	constructor() {
		this.pages = [ new LeftPage(), new RightPage(), new MainPage() ]
		this.pageHistory = [ this.pages[2] ]
	}

	get currentTitle() {
		if (this.pageHistory.length == 0) {
			return "Corrupt"
		}
		return this.pageHistory[this.pageHistory.length-1].title
	}

	goLeft() {
		this.pageHistory[0] = this.pages[0]
	}

	goRight() {
		this.pageHistory[0] = this.pages[1]
	}

	show() {
		console.log( this.pageHistory.length )
		console.dir( this.pageHistory[0] )
	}
}