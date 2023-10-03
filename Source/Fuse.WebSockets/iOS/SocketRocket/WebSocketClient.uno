using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.WebSocket;

namespace SocketRocket
{
	[Require("includeDirectory", "@('include/':path)")]
	[Require("linkDirectory", "@('lib/':path)")]
	[Require("linkLibrary", "SocketRocket")]
	[Require("source.include", "SRWebSocket.h")]
	[Require("xcode.framework", "Security.framework")]
	[Require("xcode.framework", "CFNetwork.framework")]
	[Require("xcode.framework", "Foundation.framework")]
	[Require("linkLibrary", "icucore")]
	[ForeignInclude(Language.ObjC, "iOS/SocketRocket/WebSocketClientObjc.h")]
	extern(iOS) public class WebSocketClient : IWebSocketClient, IDisposable
	{
		ObjC.Object _webSocket;
		Action _open;
		Action _close;
		Action<string> _error;

		public void Create(string uri,
			string[] protocols,
			Action open,
			Action close,
			Action<string> error,
			Action<string> receiveMessage,
			Action<byte[]> receiveData)
		{
			_open = open;
			_close = close;
			_error = error;

			_webSocket = Create(uri, protocols, HandleEvent, receiveMessage, receiveData);
		}

		[Foreign(Language.ObjC)]
		ObjC.Object Create(string url,
			string[] protocols,
			Action<string, string> eventHandler,
			Action<string> receiveMessageHandler,
			Action<byte[]> receiveDataHandler)
		@{
			return [[WebSocketClientObjc alloc]
							initWithUrl:url
							protocols:[protocols copyArray]
							eventHandler:eventHandler
							onReceivedMessage:receiveMessageHandler
							onReceivedData:^(uint8_t * data, NSUInteger length) {
								id<UnoArray> arr = @{byte[]:new((int)length)};
								memcpy(arr.unoArray->Ptr(), data, length);
								receiveDataHandler(arr);
							}];
		@}

		[Foreign(Language.ObjC)]
		public void Connect()
		@{
			[@{WebSocketClient:of(_this)._webSocket:get()} connect];
		@}

		[Foreign(Language.ObjC)]
		public void Close()
		@{
			[@{WebSocketClient:of(_this)._webSocket:get()} disconnect];
		@}

		[Foreign(Language.ObjC)]
		public void Send(string data)
		@{
			[@{WebSocketClient:of(_this)._webSocket:get()} sendString:data];
		@}

		[Foreign(Language.ObjC)]
		public void Send(byte[] data)
		@{
			const uint8_t *arrPtr = (const uint8_t *)[data unoArray]->Ptr();
			[@{WebSocketClient:of(_this)._webSocket:get()} sendData:arrPtr length:[data count]];
		@}

		[Foreign(Language.ObjC)]
		public void SetHeader(string key, string value)
		@{
			[@{WebSocketClient:of(_this)._webSocket:get()} setHeaderKey:key withValue:value];
		@}

		void HandleEvent(string type, string message)
		{
			if (type == "open")
				_open();

			if (type == "close")
				_close();

			if (type == "error")
				_error(message);
		}

		public void Dispose()
		{
			_webSocket = null;
		}
	}
}
