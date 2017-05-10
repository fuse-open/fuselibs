using Uno;

using Uno.Net.Http;
using Experimental.Cache;

namespace Experimental.Http
{
	class TextLoader : Loader
	{
		public Action<HttpResponseHeader,String> Callback;
		
		protected override void PrepareRequest( HttpMessageHandlerRequest request )
		{
			request.SetResponseType( HttpResponseType.String );
		}
		
		protected override void CompleteLoading( HttpMessageHandlerRequest resp )
		{
			OnBufferLoaded(resp.GetResponseContentString());
		}
		
		void OnBufferLoaded( String data )
		{
			var record = OpenRecord();
			if (record != null)
			{
				var textWriter = new Uno.IO.StreamWriter(record.Stream);
				textWriter.Write(data);
				CloseRecord(record);
			}
			
			Callback(Header, data);
		}
			
		protected override void LoadCacheData()
		{
			Callback(Header, _loadedCache);
		}
		
		String _loadedCache;
		protected override bool LoadCacheRaw(ICacheReader record)
		{
			var reader = new Uno.IO.StreamReader(record.Stream);
			_loadedCache = reader.ReadToEnd();
			return true;
		}
	}
}
