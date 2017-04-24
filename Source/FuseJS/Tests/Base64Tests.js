
var Base64 = require("FuseJS/Base64");

function encodeBuffer_is_successful() {
	var data = new ArrayBuffer(4);
	var view = new Int32Array(data);
	view[0] = 0x1337;
	var encoded = Base64.encodeBuffer(data);
	test.assert(encoded === 'NxMAAA==', "Base64.encodeBuffer encoded to wrong base64 string");
}

function decodeBuffer_is_successful() {
	var data = Base64.decodeBuffer("NxMAAA==");
	var view = new Int32Array(data);
	test.assert(view[0] === 0x1337, "Base64.decodeBuffer decoded buffer has wrong content");
}

encodeBuffer_is_successful();
decodeBuffer_is_successful();

