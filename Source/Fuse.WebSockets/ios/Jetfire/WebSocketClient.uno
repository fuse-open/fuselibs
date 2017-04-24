using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.WebSocket;

namespace Jetfire
{
	[Require("Xcode.FrameworkDirectory", "@('Jetfire-iOS/Carthage/Build/iOS':Path)")]
	[Require("Xcode.EmbeddedFramework", "@('Jetfire-iOS/Carthage/Build/iOS/Jetfire.framework':Path)")]
	[Require("Xcode.Framework", "Security.framework")]
	[Require("Xcode.Framework", "CFNetwork.framework")]
	[ForeignInclude(Language.ObjC, "ios/Jetfire/WebSocketClientObjc.h")]
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
								id<UnoArray> arr = @{byte[]:New((int)length)};
								memcpy(arr.unoArray->Ptr(), data, length);
								receiveDataHandler(arr);
							}];
		@}

		[Foreign(Language.ObjC)]
		public void Connect()
		@{
			[@{WebSocketClient:Of(_this)._webSocket:Get()} connect];
		@}

		[Foreign(Language.ObjC)]
		public void Close()
		@{
			[@{WebSocketClient:Of(_this)._webSocket:Get()} disconnect];
		@}

		[Foreign(Language.ObjC)]
		public void Send(string data)
		@{
			[@{WebSocketClient:Of(_this)._webSocket:Get()} sendString:data];
		@}

		[Foreign(Language.ObjC)]
		public void Send(byte[] data)
		@{
			const uint8_t *arrPtr = (const uint8_t *)[data unoArray]->Ptr();
			[@{WebSocketClient:Of(_this)._webSocket:Get()} sendData:arrPtr length:[data count]];
		@}

		[Foreign(Language.ObjC)]
		public void SetHeader(string key, string value)
		@{
			[@{WebSocketClient:Of(_this)._webSocket:Get()} setHeaderKey:key withValue:value];
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
