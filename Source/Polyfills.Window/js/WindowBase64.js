(function(window, base64){

	'use strict';

	window.atob = base64.decodeLatin1;
	window.btoa = base64.encodeLatin1;
})(window, require("FuseJS/Base64"));

atob = window.atob;
btoa = window.btoa;