var App = require("_$filename$_");
var images = App.getPictures();
module.exports = {
	images : images,
	currentIndex : this.Parameter.map(function(param){
		for(var i=0;i<images.length;i++){
			if(images.getAt(i).id == param.id){
				return i;
			}
		}
		return 0;
	})
}
