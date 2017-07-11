var router = null;

function initialize(inRouter){
	router = inRouter;
	gotoMainPage();
}

function gotoMainPage(){
	router.goto("MainPage");
}

function gotoDetails(item){
	router.push("DetailsPage", item);
}

function goBack(){
	router.goBack();
}

module.exports = {
	initialize : initialize,
	goBack : goBack,
	gotoMainPage : gotoMainPage,
	gotoDetails : gotoDetails
}
