var App = require("_$filename$_");
App.initializeNavigation(mainRouter);
module.exports = {
	appTitle : App.getAppTitle(),
	goBack : function() { App.getNavigation().goBack(); }
}
