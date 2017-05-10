using Uno;
using Uno.Collections;
using Uno.IO;


namespace Experimental.Cache
{
	enum DiskCacheEntryStatus
	{
		Creating,
		Valid,
		Invalid,
	}
	
	class DiskCacheEntry
	{
		public const int MagicCode = 274648125;
		
		public string Id;
		public Dictionary<string,string> Meta = new Dictionary<string,string>();
		public int FileRef;
		public long Size;
		public DiskCacheEntryStatus Status;
		public int LastUsed;
		
		public void Write( BinaryWriter w )
		{
			w.Write(MagicCode);
			w.Write(Id);
			w.Write(FileRef);
			w.Write(Size);
			w.Write( (int)Status );
			
			int c = Meta.Count;
			w.Write(c);
			foreach (var m in Meta)
			{
				w.Write(m.Key);
				w.Write(m.Value);
			}
		}
		
		static public DiskCacheEntry Load( BinaryReader r )
		{
			if (r.ReadInt() != MagicCode)
				return null;
				
			var dce = new DiskCacheEntry();
			dce.Id = r.ReadString();
			dce.FileRef = r.ReadInt();
			dce.Size = r.ReadLong();
			dce.Status = (DiskCacheEntryStatus)r.ReadInt();
			
			int c = r.ReadInt();
			for (int i=0; i < c; ++i)
			{
				var k = r.ReadString();
				var v = r.ReadString();
				dce.Meta[k] = v;
			}
			
			return dce;
		}
	}

	class ProxyStream : Stream
	{
		public Stream Backing;
		
		public override bool CanRead { get { return true; } }
		public override bool CanWrite { get { return true; } }
		public override bool CanSeek { get { return false; } }
		
		public override bool CanTimeout { get { return Backing.CanTimeout; } }
		
		public override int ReadTimeout 
		{
			get { return Backing.ReadTimeout; }
			set { Backing.ReadTimeout = value; }
		}
		
		public override int WriteTimeout 
		{
			get { return Backing.WriteTimeout; }
			set { Backing.WriteTimeout = value; }
		}
		
		public override long Length { get { return Backing.Length; } }
		public override long Position 
		{
			get { return Backing.Position; }
			set { throw new NotSupportedException(); }
		}
		
		public override void SetLength(long value) { Backing.SetLength(value); }
		
        public override int Read(byte[] dst, int byteOffset, int byteCount) 
        { return Backing.Read(dst,byteOffset,byteCount); }
        public override void Write(byte[] src, int byteOffset, int byteCount)
        { Backing.Write(src, byteOffset, byteCount); }
        public override long Seek(long byteOffset, SeekOrigin origin)
        { return Backing.Seek(byteOffset, origin); }
        public override void Flush()
        { Backing.Flush(); }
        
        public override void Dispose(bool disposing) { Backing.Dispose(disposing); }
        public override void Close() { Backing.Close(); }
	}
	
	class DiskCacheWriterStream : ProxyStream
	{
		public override bool CanRead { get { return false;} }
	}
	
	class DiskCacheReaderStream : ProxyStream
	{
		public override bool CanWrite { get { return false; } }
	}
	
	class DiskCacheWriter : ICacheWriter
	{
		public DiskCacheEntry _entry;
		public DiskCache _cache;
		DiskCacheWriterStream _stream;
		
		public void AddMeta( string key, string value )
		{
			_entry.Meta[key] = value;
		}

		public Stream Stream
		{
			get
			{
				if (_stream == null)
				{
					_stream = new DiskCacheWriterStream();
					var fname = _cache.DataFile(_entry);
					_stream.Backing = File.OpenWrite( fname );
				}
				return _stream;
			}
		}
		
		public void Close()
		{
			if (_stream != null)
			{
				_entry.Size = _stream.Position;
				_stream.Close();
			}
			_stream = null;
			
			_entry.Status = DiskCacheEntryStatus.Valid;
			_cache.Update(_entry);
		}
		
		public void Abort()
		{
			if (_stream != null)
				_stream.Close();
			_stream = null;
			
			_entry.Status = DiskCacheEntryStatus.Invalid;
			_cache.Update(_entry);
		}
	}
	
	class DiskCacheReader : ICacheReader
	{
		public DiskCacheEntry _entry;
		public DiskCache _cache;
		DiskCacheReaderStream _stream;
		
		public string GetMeta( string key )
		{
			string o;
			if (_entry.Meta.TryGetValue(key, out o) )
				return o;
			return null;
		}
		
		public long DataSize 
		{ 
			get { return _entry.Size; }
		}
		
		public Stream Stream
		{
			get
			{
				if (_stream ==null)
				{
					var fname = _cache.DataFile(_entry);	
					_stream = new DiskCacheReaderStream();
					_stream.Backing = File.OpenRead(fname);
				}
				
				return _stream;
			}
		}
		
		public void Delete()
		{	
			_cache.DeleteRecord(_entry.Id);
		}
	}

	class RecordFileDiskCache : RecordFile<DiskCacheEntry>
	{
		public RecordFileDiskCache(string filename ) : base(filename)  { }
		
		protected override DiskCacheEntry LoadRecord( BinaryReader r )
		{
			return DiskCacheEntry.Load(r);
		}
		
		protected override void SaveRecord( DiskCacheEntry record, BinaryWriter w )
		{
			record.Write(w);
		}
	}
	
	public class DiskCache : ICache
	{	
		int _fileRef;
		string _storeDir;
		public string StoreDirectory
		{
			get { return _storeDir; }
		}
	
		long _maxSize = 20000000;
		public long MaxSize
		{
			get { return _maxSize; }
			set { _maxSize = value; }
		}
		Dictionary<string, DiskCacheEntry> _entries = new Dictionary<string, DiskCacheEntry>();
		RecordFileDiskCache _index;

		public int RecordCount
		{
			get { return _entries.Count; }
		}
		
		public enum DirectoryType
		{
			CacheRelative,
			Absolute,
		}
		
		public DiskCache( string dirName, DirectoryType dt = DirectoryType.CacheRelative )
		{
			//https://github.com/fusetools/Uno/issues/11
			if (dt == DirectoryType.CacheRelative)
			{
				_storeDir = Directory.GetUserDirectory( UserDirectory.Data );
				_storeDir += "/" + dirName;
				if (!Directory.Exists(_storeDir) )
					Directory.CreateDirectory(_storeDir);
				_storeDir += "/Cache";
			}
			else
			{
				_storeDir = dirName;
			}
			
			if (!Directory.Exists(_storeDir) )
				Directory.CreateDirectory(_storeDir);
				
			_index = new RecordFileDiskCache(StoreDirectory + "/Index");
			_fileRef = 0;
			foreach (var record in _index.GetAllRecords())
			{
				_entries[record.Id] = record;
				//start at highest ID (if we had SHA library I'd prefer to just use hash of id)
				_fileRef = Math.Max(_fileRef, record.FileRef);
				_estimateSize += record.Size;
			}
			CleanDirectory();
		}
		
		public void Dispose()
		{
			_entries = null;
			_index.Close();
			_index = null;
		}
		
		public bool LoadRecord( string id, CacheLoaded onLoaded )
		{
			DiskCacheEntry e;
			if (!_entries.TryGetValue(id, out e))
				return false;
				
			var dcr = new DiskCacheReader();
			dcr._cache = this;
			dcr._entry = e;
			e.LastUsed = Experimental.Http.Internal.DateUtil.TimestampNow;
			_index.Update(e);
			onLoaded(dcr);
			return true;
		}
		
		public ICacheWriter CreateRecord( string id )
		{
			var nextId = ++_fileRef;
			
			var dcw = new DiskCacheWriter();
			dcw._cache = this;
			
			DiskCacheEntry e;
			if (!_entries.TryGetValue(id, out e))
			{
				e = new DiskCacheEntry();
				e.FileRef = nextId;
				_entries[id] = e;
			}
			dcw._entry = e;
			e.Id = id;
			e.Status = DiskCacheEntryStatus.Creating;
			e.LastUsed = Experimental.Http.Internal.DateUtil.TimestampNow;
			_index.Update(e);
			
			return dcw;
		}
		
		public void DeleteRecord( string id )
		{
			DiskCacheEntry e;
			if (!_entries.TryGetValue(id, out e))
				return;
				
			var fname = DataFile(e);
			try
			{
				if (File.Exists(fname))
					File.Delete(fname);
			}
			catch(Exception ex)
			{
				debug_log ex;
				debug_log "Failed to delete cache file: " + fname;
			}
			
			_entries.Remove(id);
			_index.Delete(e);
		}
		
		public void Clear()
		{
			var ids = new List<string>();
			foreach (var entry in _entries)
				ids.Add(entry.Key);
				
			foreach (var id in ids)
				DeleteRecord(id);
		}
		
		internal string DataFile( DiskCacheEntry _entry )
		{
			return StoreDirectory + "/" + _entry.FileRef;
		}
		
		long _estimateSize;
		internal void Update( DiskCacheEntry _entry )
		{
			_estimateSize += _entry.Size;
			
			if (_estimateSize > _maxSize)
				TrimCache();
				
			_index.Update(_entry);
		}
		
		void TrimCache()
		{
			long size = 0;
			foreach (var entry in _entries)
				size += entry.Value.Size;
				
			if (size < _maxSize)
				return;
				
			var order = new List<DiskCacheEntry>();
			foreach (var entry in _entries)
				order.Add( entry.Value );
				
			order.Sort(LastUsed);
			
			foreach (var entry in order)
			{
				if (entry.Status == DiskCacheEntryStatus.Creating)
					continue;
					
				DeleteRecord(entry.Id);
				size -= entry.Size;
				if (size < _maxSize/2)
					break;
			}
			
			_estimateSize = size;
		}
		
		int LastUsed(DiskCacheEntry a, DiskCacheEntry b)
		{
			return a.LastUsed - b.LastUsed;
		}
		
		void CleanDirectory()
		{
			var known = new HashSet<string>();
			known.Add( "Index" );
			foreach (var e in _entries)
				known.Add(""+e.Value.FileRef);
				
			foreach (var file in Directory.EnumerateFiles( StoreDirectory))
			{
				var baseName = BaseName(file);
				if (known.Contains(baseName))
					continue;
					
				var fname = StoreDirectory + "/" + baseName;
				try
				{
					File.Delete(fname);
				}
				catch(Exception e)
				{
					debug_log e;
					debug_log "Failed to delete cache file: " + fname;
				}
			}
		}
		
		string BaseName(string file)
		{
			int end = -1;
			while(true)
			{
				int e = file.IndexOf( '/', end+1 );
				int f = file.IndexOf( '\\', end+1 );
				int g = Math.Max(e,f);
				if (g == -1)
					break;
				end = g;
			}
			
			return file.Substring(end+1);
		}
	}
}
	