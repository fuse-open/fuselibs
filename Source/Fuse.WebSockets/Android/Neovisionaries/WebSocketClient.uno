using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.WebSocket;

namespace Neovisionaries
{
	[ForeignInclude(Language.Java, "com.foreign.Uno.*",
									"com.neovisionaries.ws.client.*",
									"java.io.IOException",
									"java.util.List",
									"java.util.Map")]
	internal extern(Android) class WebSocketClient : IWebSocketClient, IDisposable
	{
		Java.Object _webSocket;

		[Foreign(Language.Java)]
		public void Create(string url,
			string[] protocols,
			Action open,
			Action close,
			Action<string> error,
			Action<string> receiveMessageHandler,
			Action<byte[]> receiveDataHandler)
		@{
			try {
				WebSocket webSocket = new WebSocketFactory().createSocket(url);
				for (String protocol : protocols.copyArray()) {
					webSocket.addProtocol(protocol);
				}
				webSocket.addListener(new WebSocketAdapter() {
					@Override
					public void onError(WebSocket websocket, WebSocketException cause) {
						error.run(cause.getMessage());
					}
					
					@Override
					public void onConnectError(WebSocket websocket, WebSocketException cause) throws Exception {
						error.run(cause.getMessage());
					}
					
					@Override
					public void onConnected(WebSocket websocket, Map<String, List<String>> headers) {
						open.run();
					}
					
					@Override
					public void onDisconnected(WebSocket websocket, WebSocketFrame serverCloseFrame, WebSocketFrame clientCloseFrame, boolean closedByServer) {
						close.run();
					}
					
					@Override
					public void onTextMessage(WebSocket websocket, String message) {
						receiveMessageHandler.run(message);
					}
					
					@Override
					public void onBinaryMessage(WebSocket websocket, byte[] binary) throws Exception {
						receiveDataHandler.run(new com.uno.ByteArray(binary));
					}
				});
				@{WebSocketClient:Of(_this)._webSocket:Set(webSocket)};
			} catch(java.io.IOException e) {
				error.run(e.getMessage());
			}
		@}

		[Foreign(Language.Java)]
		public void Connect()
		@{
			WebSocket webSocket = (WebSocket) @{WebSocketClient:Of(_this)._webSocket:Get()};
			webSocket.connectAsynchronously();
		@}

		[Foreign(Language.Java)]
		public void Close()
		@{
			WebSocket webSocket = (WebSocket) @{WebSocketClient:Of(_this)._webSocket:Get()};
			webSocket.sendClose();
		@}

		[Foreign(Language.Java)]
		public void Send(string data)
		@{
			WebSocket webSocket = (WebSocket) @{WebSocketClient:Of(_this)._webSocket:Get()};
			webSocket.sendText(data);
		@}

		[Foreign(Language.Java)]
		public void Send(byte[] data)
		@{
			WebSocket webSocket = (WebSocket) @{WebSocketClient:Of(_this)._webSocket:Get()};
			webSocket.sendBinary(data.copyArray());
		@}

		[Foreign(Language.Java)]
		public void SetHeader(string key, string value)
		@{
			//WebSocketJava webSocket = (WebSocketJava) @{WebSocketClient:Of(_this)._webSocket:Get()};
			// TODO: webSocket.SetHeader(key, value);
		@}

		public void Dispose()
		{
			_webSocket = null;
		}
	}
}
