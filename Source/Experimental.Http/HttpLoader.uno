using Uno;
using Uno.Collections;
using Uno.IO;

using Uno.Net.Http;

namespace Experimental.Http
{
	static public class HttpLoader
	{
		public static void LoadBinary(string requestUri, bool cacheResponse, Action<HttpResponseHeader, byte[]> callback,
			Action<string> error)
		{
			if (callback == null)
				throw new Exception( "LoadBinary requires callback action" );
			if (error == null)
				throw new Exception( "LoadBinary requires error action" );

			var bl = new BinaryLoader();
			bl.Uri = requestUri;
			bl.Method = "GET";
			bl.Callback = callback;
			bl.ErrorCallback = error;
			bl.Initiate(cacheResponse);
		}
	}
}
