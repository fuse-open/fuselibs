using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.WebSocket;

namespace WebSocketSharp
{
	internal extern(DOTNET) class WebSocketClient : IWebSocketClient, IDisposable
	{
		WebSocketSharp.WebSocket _webSocket;
		Action _open;
		Action _close;
		Action<string> _error;
		Action<string> _receiveMessageHandler;
		Action<byte[]> _receiveDataHandler;

		public void Create(string uri,
			string[] protocols,
			Action open,
			Action close,
			Action<string> error,
			Action<string> receiveMessageHandler,
			Action<byte[]> receiveDataHandler)
		{
			_open = open;
			_close = close;
			_error = error;
			_receiveMessageHandler = receiveMessageHandler;
			_receiveDataHandler = receiveDataHandler;

			_webSocket = new WebSocketSharp.WebSocket(uri, protocols);

			var host = new Uri(uri).Host;
			// NOTE: I'm enabling tls1.2 nanually here (since we export to .net 4.5), should probably check if its supported first if exported to other targets https://msdn.microsoft.com/en-us/library/windows/desktop/bb870930(v=vs.85).aspx#listing_supported_cipher_suites
			// Mono does not support tls 1.1 and 1.2 until Mono 4.6 http://tirania.org/blog/archive/2016/Sep-30.html
			_webSocket.SslConfiguration = new ClientSslConfiguration(host, null, SslProtocols.Default | SslProtocols.Tls11 | SslProtocols.Tls12, false);
			
			_webSocket.OnOpen += Opened;
			_webSocket.OnClose += Closed;
			_webSocket.OnError += Error;
			_webSocket.OnMessage += MessageReceived;
		}
		
		void Opened(object sender, object args) {
			_open();
		}

		void Closed(object sender, CloseEventArgs args) {
			_close();
		}

		void Error(object sender, ErrorEventArgs args) {
			_error(args.Exception.ToString());
		}

		void MessageReceived(object sender, WebSocketSharp.MessageEventArgs args) {
			if (args.IsText)
				_receiveMessageHandler(args.Data);
			else
				_receiveDataHandler(args.RawData);
		}


		public void Connect()
		{
			_webSocket.ConnectAsync();
		}

		public void Close()
		{
			_webSocket.Close();
		}

		public void Send(string message)
		{
			_webSocket.Send(message);
		}

		public void Send(byte[] data)
		{
			_webSocket.Send(data);
		}

		public void SetHeader(string key, string value)
		{

		}

		public void Dispose()
		{
			if (_webSocket != null)
				_webSocket = null;
		}
	}
}