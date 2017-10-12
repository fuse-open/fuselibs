using Uno;
using Uno.Collections;
using Uno.IO;

using Uno.Net.Http;

namespace Experimental.Http
{
	static class LoaderConst
	{
		public static HttpMessageHandler Handler;
	}

	class BinaryLoader
	{
		public Action<HttpResponseHeader,Buffer> Callback;
		public Action<string> ErrorCallback;
		public String Uri;
		public String Method;

		public void Initiate()
		{
			MakeRequest();
		}

		public void MakeRequest()
		{
			if (LoaderConst.Handler == null)
				LoaderConst.Handler = new HttpMessageHandler();

			var request = LoaderConst.Handler.CreateRequest(Method, Uri, Fuse.UpdateManager.Dispatcher);
			request.Error += OnError;
			request.Done += OnLoaded;
			request.SetResponseType( HttpResponseType.ByteArray );
			request.SendAsync();
		}

		HttpResponseHeader _header;
		protected HttpResponseHeader Header
		{
			get { return _header; }
		}

		public void OnLoaded( HttpMessageHandlerRequest resp )
		{
			_header = new HttpResponseHeader();
			_header.StatusCode = resp.GetResponseStatus();
			//_header.ReasonPhrase = resp.ReasonPhrase;

			_header.Headers = ExtractHeaders(resp.GetResponseHeaders());
			Callback(Header, new Buffer(resp.GetResponseContentByteArray()));
		}

		Dictionary<string, string> ExtractHeaders(string headers)
		{
			var res = new Dictionary<string, string>();
			foreach (var header in headers.Split('\n'))
			{
				if (!string.IsNullOrEmpty(header.Trim()))
				{
					var arr = header.Split(':');
					var actualValue = arr.Length > 1 ? header.Substring(header.IndexOf(":") + 1).Trim() : string.Empty;
					res.Add(arr[0].Trim().ToLower(), actualValue);
				}
			}
			return res;
		}

		public void OnError(HttpMessageHandlerRequest msg, string reason )
		{
			ErrorCallback(reason);
		}
	}
}
