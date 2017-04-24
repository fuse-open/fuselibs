(function(window, timer){

	'use strict';
	
	window.setTimeout = function(handler, timeout, args) {
		//TODO: Add support for multiple args
		if(typeof handler === "function")
			return timer.create(handler, timeout, false, args);
		else
			console.log("not supported");
	}
	window.clearTimeout = function(handle) {
		timer.delete(handle);
	}

	window.setInterval = function(handler, timeout, args) {
		if(typeof handler === "function")
			return timer.create(handler, timeout, true, args);
		else
			console.log("not supported");
	}
	window.clearInterval = function(handle) {
		timer.delete(handle);
	}
	
})(window, require("FuseJS/Timer"));

setTimeout = window.setTimeout;
clearTimeout = window.clearTimeout;

setInterval = window.setInterval;
clearInterval = window.clearInterval;