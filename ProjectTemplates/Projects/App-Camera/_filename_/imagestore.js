var Camera = require("FuseJS/Camera");
var Observable = require("FuseJS/Observable");
var Environment = require("FuseJS/Environment");
var ImageTools = require("FuseJS/ImageTools");
var allImages = Observable();
var id = 0;

module.exports = {
	getPictures : function(){
		return allImages;
	},
	takeNewPicture : function(){
		if(Environment.mobile){
			Camera.takePicture(1024, 1024).then(function(image){
				var options = {
					desiredWidth:128, 
					desiredHeight:128, 
					mode:ImageTools.SCALE_AND_CROP,
					performInPlace:false
				};
				ImageTools.resize(image, options).then(function(thumbnailImage){
					allImages.add({thumbnailPath:thumbnailImage.path, imagePath:image.path, id:id++});
				});
			})
		}else{
			// If we don't have a camera, fetch a random cat picture
			var catUrl = "http://thecatapi.com/api/images/get?format=src&type=png&rnd=" + Date.now();
			allImages.add({thumbnailPath:catUrl, imagePath:catUrl, id:id++});
		}
	}
}
