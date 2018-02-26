let globalInstanceCount = 0;

export default class {
	constructor(scrollView) {
		this.instanceCount = ++globalInstanceCount;
		this.scrollView = scrollView;
	}

	doScroll() {
		this.scrollView.seekTo(0, 1337);
	}
}