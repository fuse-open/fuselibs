using Uno;

using Uno.Net.Http;
using Experimental.Cache;

namespace Experimental.Http
{
	class BinaryLoader : Loader
	{
		public Action<HttpResponseHeader,Buffer> Callback;
		
		protected override void PrepareRequest( HttpMessageHandlerRequest request )
		{
			request.SetResponseType( HttpResponseType.ByteArray );
		}
		
		protected override void CompleteLoading( HttpMessageHandlerRequest resp )
		{
			OnBufferLoaded(resp.GetResponseContentByteArray());
		}
		
		void OnBufferLoaded( byte[] data )
		{
			var record = OpenRecord();
			if (record != null)
			{
				record.Stream.Write(data,0,data.Length);
				CloseRecord(record);
			}
			
			Callback(Header, new Buffer(data));
		}
			
		protected override void LoadCacheData()
		{
			Callback(Header, _loadedCache);
		}
		
		Buffer _loadedCache;
		protected override bool LoadCacheRaw(ICacheReader record)
		{
			var len = (int)(record.Stream.Length - record.Stream.Position);
			var b  = new byte[len];
			record.Stream.Read(b,0,len);
			_loadedCache = new Buffer(b);
			return true;
		}
	}
}
