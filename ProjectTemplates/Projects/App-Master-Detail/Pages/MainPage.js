var App = require("_$filename$_");
module.exports = {
	data : App.getData(),
	onItemTapped : function(args){
		App.showDetailsForItem(args.data);
	}
}
