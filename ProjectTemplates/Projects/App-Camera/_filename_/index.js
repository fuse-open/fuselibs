var Observable = require("FuseJS/Observable");
var ImageStore = require("_$filename$_/imagestore");
var Navigation = require("_$filename$_/navigation");
module.exports = {
	getAppTitle : function(){
		return "_$filename$_";
	},
	initializeNavigation : function(router){
		Navigation.initialize(router);
	},
	takeNewPicture : ImageStore.takeNewPicture,
	gotoImage : Navigation.gotoImage,
	getPictures : ImageStore.getPictures
}
