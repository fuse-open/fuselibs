using Uno;
using Uno.IO;

namespace Experimental.Cache
{
	public interface ICacheWriter
	{
		void AddMeta( string key, string value );
		//a write only forward-stream
		Stream Stream { get; }
		void Close();
		void Abort();
	}
	
	public interface ICacheReader
	{
		string GetMeta( string key );
		long DataSize { get; }
		//a read only forward-stream
		Stream Stream { get; }
		void Delete();
	}
	
	public delegate void CacheLoaded( ICacheReader record );
	
	public interface ICache
	{
		bool LoadRecord( string id, CacheLoaded onLoaded );
		ICacheWriter CreateRecord( string id );
		void DeleteRecord( string id );
		void Clear();
	}
}
