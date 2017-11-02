using Uno.Compiler.ExportTargetInterop;
using Uno;

namespace WebSocketSharp
{
	[DotNetType("WebSocketSharp.ErrorEventArgs")]
	extern(DOTNET) public class ErrorEventArgs
	{
		public extern Uno.Exception Exception { get; private set; }
	}

	[DotNetType("WebSocketSharp.MessageEventArgs")]
	extern(DOTNET) public class MessageEventArgs : EventArgs
	{
		public extern string Data { get; }
		public extern bool IsBinary { get; }
		public extern bool IsPing { get; }
		public extern bool IsText { get; }
		public extern byte[] RawData { get; }
	}

	[DotNetType("WebSocketSharp.CloseEventArgs")]
	extern(DOTNET) public class CloseEventArgs : EventArgs
	{}

	[DotNetType("System.Security.Cryptography.X509Certificates.X509CertificateCollection")]
	extern(DOTNET) public class X509CertificateCollection
	{}

	[DotNetType("System.Security.Authentication.SslProtocols")]
	extern(DOTNET) public enum SslProtocols
	{
		None = 0,
		Ssl2 = 12,
		Ssl3 = 48,
		Tls10 = 192,
		Tls11 = 768,
		Tls12 = 3072,
		Tls = Tls10,
		Default = Ssl3 | Tls
	}

	[DotNetType("WebSocketSharp.Net.ClientSslConfiguration")]
	extern(DOTNET) public class ClientSslConfiguration
	{
		public extern ClientSslConfiguration (
			  string targetHost,
			  X509CertificateCollection clientCertificates,
			  SslProtocols enabledSslProtocols,
			  bool checkCertificateRevocation);
	}

	[DotNetType("System.Uri")]
	extern(DOTNET) public class Uri
	{
		public extern Uri(string uriString);
		public extern string Host { get; }
	}

	[DotNetType("WebSocketSharp.WebSocket")]
	extern(DOTNET) public class WebSocket : Uno.IDisposable
	{
		public extern ClientSslConfiguration SslConfiguration { get; set; }
		public extern void ConnectAsync();

		public extern event EventHandler OnOpen { add; remove; }

		public extern event EventHandler<MessageEventArgs> OnMessage { add; remove; }

		public extern WebSocket(string url, params string[] protocols);

		public extern void Send(string message);

		public extern void Send(byte[] data);

		public extern void Close();

		public extern event EventHandler<CloseEventArgs> OnClose { add; remove; }

		public extern event EventHandler<ErrorEventArgs> OnError { add; remove; }

		public void Uno.IDisposable.Dispose() {
		 //   Close();
		}
	}
}
