using Uno;
using Uno.Collections;
using Uno.IO;

using Uno.Net.Http;

namespace Experimental.Http
{
	static public class HttpLoader
	{
		static Cache.ICache _cache;
		
		//in seconds
		static int _maxAge = 60*60*24; //1-day
		static public int CacheMaxAge
		{
			get { return _maxAge; }
			set { _maxAge = value; }
		}
		
		static Cache.DiskCache _diskCache;
		public static void EnableDiskCaching( string appName, long maxSize = 0 )
		{
			if (_diskCache == null)
				_cache = _diskCache = new Cache.DiskCache(appName);
			if (maxSize != 0)
				_diskCache.MaxSize = maxSize;
		}
		
		static public Cache.ICache Cache
		{
			get { return _cache; }
		}
		
		public static void Discard(string requestUri)
		{
			if (_cache != null)
			{
				//get rid of any matching
				_cache.DeleteRecord( BinaryLoader.ConstructRecordId("GET",requestUri) );
			}
		}
		
		public static void LoadBinary(string requestUri, Action<HttpResponseHeader,Buffer> callback,
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
			bl.Cache = _cache;
			bl.Initiate();
		}
	}
}
