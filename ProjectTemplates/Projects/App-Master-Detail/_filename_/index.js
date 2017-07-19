var Observable = require("FuseJS/Observable");
var Navigation = require("_$filename$_/navigation");

var data = []
for(var i = 0; i<100; i++)
	data.push({title:"Item "+i, id:i})

module.exports = {
	getAppTitle : function(){
		return "_$filename$_";
	},
	getNavigation : function(){
		return Navigation;
	},
	getData : function(){
		return data;
	},
	showDetailsForItem : function(item){
		Navigation.gotoDetails(item);
	},
	initializeNavigation : function(router){
		Navigation.initialize(router);
	}
}
