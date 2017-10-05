using Uno;
using Uno.Collections;
using Uno.IO;

using Uno.Net.Http;
using Experimental.Cache;

namespace Experimental.Http
{
	static class LoaderConst
	{
		public const string MetaUpdated = "updated";
		public const string MetaEtag = "etag";
		public static HttpMessageHandler Handler;
	}

	class BinaryLoader
	{
		public Action<HttpResponseHeader,Buffer> Callback;
		public Action<string> ErrorCallback;
		public ICache Cache;
		public String Uri;
		public String Method;

		public void Initiate()
		{
			if (Cache != null)
			{
				var has = Cache.LoadRecord( ConstructRecordId(Method,Uri), OnCacheReady );
				if (!has)
					MakeRequest();
			}
			else
			{
				MakeRequest();
			}
		}

		public void MakeRequest()
		{
			if (LoaderConst.Handler == null)
				LoaderConst.Handler = new HttpMessageHandler();

			var request = LoaderConst.Handler.CreateRequest(Method, Uri, Fuse.UpdateManager.Dispatcher);
			request.Error += OnError;
			request.Done += OnLoaded;
			if (_cacheRecord != null)
			{
				var etag = _cacheRecord.GetMeta( LoaderConst.MetaEtag );
				if (etag != null)
					request.SetHeader("If-None-Match", etag);
			}

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
			if (_cacheRecord != null && resp.GetResponseStatus() == 304)
			{
				if (LoadCache(_cacheRecord))
					return;
			}

			_header = new HttpResponseHeader();
			_header.StatusCode = resp.GetResponseStatus();
			//_header.ReasonPhrase = resp.ReasonPhrase;

			_header.Headers = ExtractHeaders(resp.GetResponseHeaders());
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

		static public string ConstructRecordId(string method, string uri)
		{
			return method + " " + uri;
		}

		protected ICacheWriter OpenRecord()
		{
			if (Cache == null || Method != "GET")
				return null;

			var record = Cache.CreateRecord( ConstructRecordId(Method,Uri) );

			var stream = record.Stream;
			var writer = new BinaryWriter(stream);
			_header.Write(writer);

			return record;
		}

		protected void CloseRecord(ICacheWriter record)
		{
			//expiration/cache control
			record.AddMeta( LoaderConst.MetaUpdated, "" + Internal.DateUtil.TimestampNow );
			if (_header.Headers.ContainsKey( "etag" ) )
				record.AddMeta( LoaderConst.MetaEtag, _header.Headers["etag"] );

			record.Close();
		}

		public void OnError(HttpMessageHandlerRequest msg, string reason )
		{
			ErrorCallback(reason);
		}

		ICacheReader _cacheRecord;
		public void OnCacheReady( ICacheReader record )
		{
			_cacheRecord = record;
			if (IsExpired(record))
			{
				MakeRequest();
				return;
			}

			if (!LoadCache(record))
			{
				_cacheRecord = null;
				MakeRequest();
			}
		}

		bool LoadCache( ICacheReader record )
		{
			var stream = record.Stream;
			var reader = new BinaryReader(stream);

			try
			{
				_header = HttpResponseHeader.Read(reader);
				if (!LoadCacheRaw(record))
					return false;
			}
			catch (Exception e)
			{
				debug_log e;
				debug_log "Failed loading caching: " + Uri;
				record.Delete();
				return false;
			}

			Callback(Header, _loadedCache);
			return true;
		}

		Buffer _loadedCache;
		protected bool LoadCacheRaw(ICacheReader record)
		{
			var len = (int)(record.Stream.Length - record.Stream.Position);
			var b  = new byte[len];
			record.Stream.Read(b,0,len);
			_loadedCache = new Buffer(b);
			return true;
		}

		bool IsExpired( ICacheReader record )
		{
			try
			{
				var updatedStr = record.GetMeta( LoaderConst.MetaUpdated );
				if (updatedStr == null)
					return true;

				int updated = Int.Parse(updatedStr);
				int age = Internal.DateUtil.TimestampNow - updated;

				if (age > HttpLoader.CacheMaxAge)
					return true;

				//FEATURE: HTTP Headers expiration, we lack date parsing now

				return false;
			}
			catch(Exception e)
			{
				return true;
			}
		}
	}
}
