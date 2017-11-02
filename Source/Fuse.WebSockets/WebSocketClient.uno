using Uno;
using Uno.Collections;

namespace Fuse.WebSocket
{
	public class WebSocketClient
	{
		readonly IWebSocketClient _client;

		public Action Opened;
		public Action Closed;
		public Action<string> MessageReceived;
		public Action<byte[]> DataReceived;
		public Action<string> ErrorReceived;

		void OnOpen()
		{
			if (Opened != null)
				Opened();
		}

		void OnClose()
		{
			if (Closed != null)
				Closed();
		}

		void OnReceiveMessage(string message)
		{
			if (MessageReceived != null)
				MessageReceived(message);
		}

		void OnReceiveData(byte[] data)
		{
			if (DataReceived != null)
				DataReceived(data);
		}

		void OnError(string error)
		{
			if (ErrorReceived != null)
				ErrorReceived(error);
		}

		public WebSocketClient(string uri, string[] protocols)
		{
			if defined(iOS) {
				_client = new SocketRocket.WebSocketClient();
			} else if defined(Android) {
				_client = new Neovisionaries.WebSocketClient();
			} else if defined(DOTNET) {
				_client = new WebSocketSharp.WebSocketClient();
			} else {
				throw new Exception("WebSocket is not supported on this platform");
			}
			_client.Create(uri, protocols, OnOpen, OnClose, OnError, OnReceiveMessage, OnReceiveData);
		}

		public void Send(string data)
		{
			_client.Send(data);
		}

		public void Send(byte[] data)
		{
			_client.Send(data);
		}

		public void Connect()
		{
			_client.Connect();
		}

		public void Close()
		{
			_client.Close();
		}
	}

	internal interface IWebSocketClient
	{
		void Create(string uri,
			string[] protocols,
			Action open,
			Action close,
			Action<string> error,
			Action<string> receiveMessage,
			Action<byte[]> receiveData);
		void Send(string data);
		void Send(byte[] data);
		void Connect();
		void Close();
	}
}
