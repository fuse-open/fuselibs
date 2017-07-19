var ImageStore = require("_$filename$_/imagestore");
var Navigation = require("_$filename$_/navigation");
module.exports = {
	getAppTitle : function(){
		return "_$filename$_";
	},
	initializeNavigation : function(router){
		Navigation.initialize(router);
	},
	getPictures : function(){
		return ImageStore.getPictures();
	},
	takeNewPicture : function(){
		ImageStore.takeNewPicture();
	},
	getNavigation : function(){
		return Navigation;
	}
}
