export class MainPage {
}
export class DetailPage {
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