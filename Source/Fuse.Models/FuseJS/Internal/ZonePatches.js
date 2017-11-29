require("FuseJS/Internal/ZoneJS");

var EventEmitter = require("FuseJS/EventEmitter");

Zone.__load_patch("FuseJS/EventEmitter", function(global, Zone, api) {
	var patchedPrototype = api.patchEventTarget(global, [EventEmitter.prototype], {
		useGlobalCallback: false,
		addEventListenerFnName: "addListener",
		removeEventListenerFnName: "removeListener",
		prependEventListenerFnName: "prependListener",
		removeAllFnName: "removeAllListeners"
	});

	if(patchedPrototype != undefined) {
		patchedPrototype["on"] = patchedPrototype["addListener"];
	}
});

Zone.__load_patch("fuseXMLHttpRequest", function(global, Zone, api) {
	api.patchEventTarget(global, [XMLHttpRequest.prototype]);
});