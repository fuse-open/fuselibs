(function(timer, ctx){

	'use strict';
	
    ctx.setTimeout = function setTimeout(handler, timeout, args) {
        if(typeof handler === "function")
            return timer.create(handler, timeout, false, args);
        else
            console.log("not supported");
    };

    ctx.clearTimeout = function clearTimeout(handle) {
        timer.delete(handle);
    };
	
});
