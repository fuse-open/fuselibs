var router = null;

function initialize(inRouter) {
	router = inRouter;
	gotoMainPage();
}

function gotoMainPage() {
	router.goto("MainPage");
}

function gotoPicture(imageData) {
	router.push("LightBoxPage", imageData);
}

function goBack() {
	router.goBack();
}

module.exports = {
	initialize: initialize,
	goBack: goBack,
	gotoMainPage: gotoMainPage,
	gotoPicture: gotoPicture
};