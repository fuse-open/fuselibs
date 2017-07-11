var App = require("_$filename$_");
module.exports = {
	images : App.getPictures(),
	onThumbnailTapped : function(args){
		App.gotoPicture(args.data)
	},
	onTakePictureButton : function(){
		App.takeNewPicture()
	}
}
