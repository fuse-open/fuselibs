/*enum BinaryType { "blob", "arraybuffer" };
[Constructor(USVString url, optional (DOMString or sequence<DOMString>) protocols = []), Exposed=(Window,Worker)]
interface WebSocket : EventTarget {
  readonly attribute USVString url;

  // ready state
  const unsigned short CONNECTING = 0;
  const unsigned short OPEN = 1;
  const unsigned short CLOSING = 2;
  const unsigned short CLOSED = 3;
  readonly attribute unsigned short readyState;
  readonly attribute unsigned long long bufferedAmount;

  // networking
  attribute EventHandler onopen;
  attribute EventHandler onerror;
  attribute EventHandler onclose;
  readonly attribute DOMString extensions;
  readonly attribute DOMString protocol;
  void close([Clamp] optional unsigned short code, optional USVString reason);

  // messaging
  attribute EventHandler onmessage;
  attribute BinaryType binaryType;
  void send(USVString data);
  void send(Blob data);
  void send(ArrayBuffer data);
  void send(ArrayBufferView data);
};

[Constructor(DOMString type, optional CloseEventInit eventInitDict), Exposed=(Window,Worker)]
interface CloseEvent : Event {
  readonly attribute boolean wasClean;
  readonly attribute unsigned short code;
  readonly attribute USVString reason;
};

dictionary CloseEventInit : EventInit {
  boolean wasClean = false;
  unsigned short code = 0;
  USVString reason = "";
};*/


WebSocket = (function(window, WebSocketClient) {

	'use strict';

	var WebSocket = function WebSocket(url) {

		var protocols = [];
		if (arguments.length > 1) {
			var p = arguments[1];
			if (typeof p === 'string') {
				protocols.push(p);
			} else if (Array.isArray(p)) {
				protocols = p;
			}
		}

		var obj = Object.create(WebSocket.prototype);

		var readyState = obj.CONNECTING;
		var binaryType = "arraybuffer";


		var client = new WebSocketClient(url, protocols);

		client.on('open', function() {
			readyState = obj.OPEN;
			handleEvent(obj, 'open');
		}).on('error', function(message) {
			readyState = obj.CLOSED;
			handleEvent(obj, 'error', message);
		}).on('receive', function(message) {
			handleEvent(obj, 'message', message);
		}).on('close', function() {
			readyState = obj.CLOSED;
			handleEvent(obj, 'close');
		});

		Object.defineProperties(obj, {
			onopen: createEventProperty(obj, "open"),
			onclose: createEventProperty(obj, "close"),
			onerror: createEventProperty(obj, "error"),
			onmessage: createEventProperty(obj, "message"),
			url: { value: url },
			readyState: { get: function() { return readyState; } },
			binaryType: {
				get: function() { return binaryType; },
				set: function(value) { /* Add support for blob binaryType = value; */ }
			}
		});/*TODO: bufferedAmount, extensions, protocol*/
		obj.send = client.send;
		obj.close = function(code, reason) {
			readyState = obj.CLOSING;
			client.close(code || 0, reason || '');
		}

		client.connect();
		return obj;
	}

	function handleEvent(obj, type, data) {
		if (typeof obj.dispatchEvent === 'function') {
			obj.dispatchEvent({ type: type, data: data });
		}
	}

	function createEventProperty(obj, type) {
		var listener;
		return {
			set: function(x) {
				obj.removeEventListener(type, listener);
				obj.addEventListener(type, listener = x);
			},
			get: function() {
				return listener;
			}
		};
	}
	
	WebSocket.CONNECTING = 0;
	WebSocket.OPEN = 1;
	WebSocket.CLOSING = 2;
	WebSocket.CLOSED = 3;

	WebSocket.prototype.CONNECTING = 0;
	WebSocket.prototype.OPEN = 1;
	WebSocket.prototype.CLOSING = 2;
	WebSocket.prototype.CLOSED = 3;

	if(typeof window.EventTarget != 'undefined') {
		WebSocket.prototype.addEventListener = window.EventTarget.prototype.addEventListener;
		WebSocket.prototype.removeEventListener = window.EventTarget.prototype.removeEventListener;
		WebSocket.prototype.dispatchEvent = window.EventTarget.prototype.dispatchEvent;
	}

	return window.WebSocket = WebSocket;

})(window, require('FuseJS/WebSocketClient'));
