export class MainPage {
	constructor() {
		//TODO: Shouldn't be required (Path can default to ClassName)
		this.$path = "MainPage"
	}
}
export class DetailPage {
	constructor() {
		//TODO: Shouldn't be required (Path can default to ClassName)
		this.$path = "DetailPage"
	}
}

export default class MutatePages {
	constructor() {
		this.pages = [new MainPage()];
	}

	pushPage() {
		this.pages.push(new DetailPage());
	}

	popPage() {
		this.pages.pop();
	}
}