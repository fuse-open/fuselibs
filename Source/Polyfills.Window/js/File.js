File = function() {
	 this.name = "";
	 this.path = "";
}

FileReader = (function(FileReaderImpl) {

	'use strict';

	return function() {
		var self = this;
		
		self.readyState = 0;
		self.result;
		self.onloadend = null;

		self.readAsDataURL = function(file) {
		 	FileReaderImpl.readAsDataURL(file.path).then(function(base64) {
		 		self.readyState = 2;
			 	self.result = base64;	
			 	self.onloadend();	
		 	});
		 
		 	self.readyState = 1;
		}

		self.readAsText = function(file) {
		 	FileReaderImpl.readAsText(file.path).then(function(text) {
		 		self.readyState = 2;
			 	self.result = text;	
			 	self.onloadend();	
		 	});
		 
		 	self.readyState = 1;
		}
	};

})(require("FuseJS/FileReaderImpl"));