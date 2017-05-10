(function (window, HttpClient) {

	'use strict';
	
	var HttpRequestState = {
		Uninitialized : 0,
		Opened : 1,
		Sent : 2,
		HeadersReceived : 3,
		Loading : 4,
		Done : 5,
		Aborted : 6,
		Errored : 7,
		TimedOut : 8,
	};

	var ProgressEvent = function ProgressEvent(loaded, total, lengthComputable) {
		Object.defineProperties(this, {
			'total' : { value: total },
			'loaded' : { value: loaded },
			'lengthComputable' : { value: lengthComputable }
		});
	};

	var fuseXMLHttpRequest = function fuseXMLHttpRequest() {
		var a = Object.create(fuseXMLHttpRequest.prototype);
		var propertyDescriptors = new Object();

		propertyDescriptors._fuseHttpClient = {
			value: new HttpClient()
		};

		propertyDescriptors._fuseHttpRequest = {
			value: null,
			writable: true
		};

		propertyDescriptors.status = {
			get: function () {
				if(this._fuseHttpRequest === null) return 0;
				return this._fuseHttpRequest.getResponseStatus();
			}
		};
		
		propertyDescriptors.statusText = {
			get: function () {
				if(this._fuseHttpRequest === null) return "";
				return this._fuseHttpRequest.getResponseReasonPhrase();
			}
		};

		propertyDescriptors.response = {
			get: function () {
				if(this._fuseHttpRequest === null) return "";
				if(this._fuseHttpRequest.getResponseType() == 1)
					return this._fuseHttpRequest.getResponseContentByteArray();
				else
					return this._fuseHttpRequest.getResponseContentString();
			}
		};

		propertyDescriptors.responseText = {
			get: function () {
				if(this._fuseHttpRequest === null) return "";
				return this._fuseHttpRequest.getResponseContentString();
			}
		};

		propertyDescriptors.responseType = {
			get: function () {
				if(this._fuseHttpRequest === null) return "text";
				return this._fuseHttpRequest.getResponseType() == 1 ? 'arraybuffer' : 'text';
			},
			set: function (value) {
				if(this._fuseHttpRequest === null) return;
				this._fuseHttpRequest.setResponseType((value.toLowerCase() == 'arraybuffer') ? 1 : 0);
			}
		};

		propertyDescriptors.readyState = {
			get: function() {
				if(this._fuseHttpRequest === null) return 0;

				var state = this._fuseHttpRequest.getState();
				if(state <= HttpRequestState.Uninitialized) return fuseXMLHttpRequest.UNSENT;
				if(state == HttpRequestState.Opened) return fuseXMLHttpRequest.OPENED;
				if(state == HttpRequestState.HeadersReceived) return fuseXMLHttpRequest.HEADERS_RECEIVED;
				if(state == HttpRequestState.Loading) return fuseXMLHttpRequest.LOADING;
				if(state >= HttpRequestState.Done) return fuseXMLHttpRequest.DONE;
				return fuseXMLHttpRequest.UNSENT;
			}
		};

		Object.defineProperties(a, propertyDescriptors);
		return a;
	};
		
	fuseXMLHttpRequest.UNSENT = 0;
	fuseXMLHttpRequest.OPENED = 1;
	fuseXMLHttpRequest.HEADERS_RECEIVED = 2;
	fuseXMLHttpRequest.LOADING = 3;
	fuseXMLHttpRequest.DONE = 4;

	fuseXMLHttpRequest.onloadstart = null;
	fuseXMLHttpRequest.onprogress = null;
	fuseXMLHttpRequest.onabort = null;
	fuseXMLHttpRequest.onerror = null;
	fuseXMLHttpRequest.onload = null;
	fuseXMLHttpRequest.ontimeout = null;
	fuseXMLHttpRequest.onloadend = null;

	fuseXMLHttpRequest.prototype.onreadystatechange = null;
	fuseXMLHttpRequest.prototype.timeout = 0;
	fuseXMLHttpRequest.prototype.withCredentials = false;
	fuseXMLHttpRequest.prototype.upload = null;

	fuseXMLHttpRequest.prototype.open = function(method, url, async, username, password) {
		var self = this;
		var progressEvent = new ProgressEvent(0, 0, false);
		var contentLength = 0;

		if(self._fuseHttpRequest !== null)
			self._fuseHttpRequest.abort();

		self._fuseHttpRequest = self._fuseHttpClient.createRequest(method, url);
		self._fuseHttpRequest.enableCache(true);
		self._fuseHttpRequest.setResponseType(0);

		if (self._fuseHttpRequest.getState() === HttpRequestState.Opened) {
			dispatch.call(self, 'readystatechange');
		}

		self._fuseHttpRequest.onstatechanged = function(state) {
			if (state === HttpRequestState.HeadersReceived) {
				dispatch.call(self, 'readystatechange');

				var cl = parseInt(self.getResponseHeader('Content-Length'));
				contentLength = (cl === NaN) ? 0 : cl;
				progressEvent = new ProgressEvent(0, contentLength, contentLength > 0);
				dispatch.call(self, 'loadstart', progressEvent);
			} else if (state === HttpRequestState.Loading || state === HttpRequestState.Done) {
				dispatch.call(self, 'readystatechange');
			}
		};
		self._fuseHttpRequest.ondone = function() {
			dispatch.call(self, 'load');
			dispatch.call(self, 'loadend', progressEvent);
		};
		self._fuseHttpRequest.onabort = function() {
			dispatch.call(self, 'abort');
			dispatch.call(self, 'loadend', progressEvent);
		};
		self._fuseHttpRequest.onerror = function(error) {
			dispatch.call(self, 'error', new Error(error));
			dispatch.call(self, 'loadend', progressEvent);
		};
		self._fuseHttpRequest.onprogress = function(current, total, hastotal) {
			progressEvent = new ProgressEvent(current, total, hastotal);
			dispatch.call(self, 'progress', progressEvent);
		};
		self._fuseHttpRequest.ontimeout = function() {
			dispatch.call(self, 'timeout');
			dispatch.call(self, 'loadend', progressEvent);
		};
	}

	fuseXMLHttpRequest.prototype.send = function(data) {
		if(this._fuseHttpRequest !== null){
			this._fuseHttpRequest.setTimeout(this.timeout);
			this._fuseHttpRequest.sendAsync(data);
		}
		else
			throw "InvalidStateError";
	}
	
	fuseXMLHttpRequest.prototype.setRequestHeader = function(header, value) {
		if(this._fuseHttpRequest === null) return;
		return this._fuseHttpRequest.setHeader(header, value + "");
	}

	fuseXMLHttpRequest.prototype.abort = function() {
		if(this._fuseHttpRequest === null) return;
		return this._fuseHttpRequest.abort();
	}

	fuseXMLHttpRequest.prototype.getResponseHeader = function(header) {
		if(this._fuseHttpRequest === null) return;
		return this._fuseHttpRequest.getResponseHeader(header);
	}

	fuseXMLHttpRequest.prototype.overrideMimeType = function(mime) {
		// Ignore
	}

	fuseXMLHttpRequest.prototype.getAllResponseHeaders = function() {
		if(this._fuseHttpRequest === null) return;
		return this._fuseHttpRequest.getResponseHeaders();
	}

	if(window.EventTarget != 'undefined') {
		fuseXMLHttpRequest.prototype.addEventListener = window.EventTarget.prototype.addEventListener;
		fuseXMLHttpRequest.prototype.removeEventListener = window.EventTarget.prototype.removeEventListener;
		fuseXMLHttpRequest.prototype.dispatchEvent = window.EventTarget.prototype.dispatchEvent;
	}
	
	function isAnyObject(value) {
		return value != null && (typeof value === 'object' || typeof value === 'function');
	}

	function dispatch(eventName, arg) {
		if(typeof this.dispatchEvent === 'function') {
			if(typeof arg === 'undefined')
				arg = {};
			
			if(isAnyObject(arg))
				arg.type = eventName;
			else
				throw new Error("Invalid event object");

			this.dispatchEvent(arg);
		}

		if(typeof this['on' + eventName] === 'function') {
			if(typeof arg === 'undefined')
				this['on' + eventName]();
			else
				this['on' + eventName](arg);
		}
	}

	window.XMLHttpRequest = fuseXMLHttpRequest;

})(window, require('FuseJS/Http'));

XMLHttpRequest = window.XMLHttpRequest;