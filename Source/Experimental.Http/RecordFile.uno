using Uno;
using Uno.Collections;
using Uno.IO;

namespace Experimental.Cache
{
	enum RecordStatus
	{
		Free,
		Item,
		Corrupt,
	}
	
	class RecordHeader
	{
		public const int MagicCode = 473648345;
		
		public RecordStatus Status;
		public int Size;
		public int Used;
		
		public long Position;
		public RecordHeader Prev, Next;

		public const int StreamSize = sizeof(int)*4;
		
		public void Write( BinaryWriter w )
		{
			w.Write(MagicCode);
			w.Write((int)Status);
			w.Write(Size);
			w.Write(Used);
		}
		
		static public RecordHeader Read( BinaryReader r )
		{
			var rh = new RecordHeader();
			var mc = r.ReadInt();
			rh.Status = (RecordStatus)r.ReadInt();
			rh.Size = r.ReadInt();
			rh.Used = r.ReadInt();
			
			if (mc != MagicCode)
				rh.Status = RecordStatus.Corrupt;
			return rh;
		}
	}
	
	public abstract class RecordFile<T>
	{
		string _filename;
		Stream _stream;
		BinaryWriter _writer;
		
		protected RecordFile( string filename )
		{
			_filename = filename;
			
			LoadCurrent();
			_stream = File.OpenWrite(_filename);
			_writer = new BinaryWriter(_stream);
			
			//UNO: https://github.com/fusetools/Uno/issues/25
			//must rewrite all records otherwise file is empty `OpenWrite` truncates
			var h = _firstRecord;
			while (h != null)
			{	
				Write(h);
				h = h.Next;
			}
			foreach (var record in _records)
			{
				Write(record.Value);
				SaveRecord(record.Key,_writer);
			}
				
			_stream.Flush();
		}
		
		public void Close()
		{
			_stream.Close();
			_stream = null;
			_writer = null;
		}
		
		void LoadCurrent()
		{
			Stream stream = null;
			try
			{
				if (File.Exists(_filename))
				{
					stream = File.OpenRead(_filename);
					LoadBlocks(stream);
					stream.Close();
				}
			}
			catch(Exception e)
			{
				debug_log e;
				if (stream != null)
					stream.Close();
				return;
			}
		}

		Dictionary<T,RecordHeader> _records = new Dictionary<T,RecordHeader>();
		RecordHeader _firstRecord;
		
		void LoadBlocks(Stream stream)
		{
			var r = new BinaryReader(stream);
			
			RecordHeader prev = null;
			long position = 0;
			while( position < stream.Length )
			{
				stream.Seek(position, SeekOrigin.Begin);
				
				var rh = RecordHeader.Read(r);
				if (rh.Status == RecordStatus.Corrupt)
				{
					debug_log "Corrupt record file: header";
					break;
				}
				
				rh.Position = position;
				rh.Prev = prev;
				if (prev != null)
					prev.Next = rh;
				else
					_firstRecord = rh;
				prev = rh;
				
				if (position + RecordHeader.StreamSize + rh.Used > stream.Length)
				{
					debug_log (position + RecordHeader.StreamSize + rh.Used) + "  >  " + stream.Length;
					debug_log "Corrupt record file: truncated";
					break;
				}
				
				if (rh.Status == RecordStatus.Item)
				{
					//failed loading will simply mark the item free
					var record = LoadRecord(r);
					if (ReferenceEquals(record,null))
						rh.Status = RecordStatus.Free;
					else
						_records[record] = rh;
				}
				
				position += RecordHeader.StreamSize + rh.Size;
			}
		}
		
		public void Update( T item )
		{
			var ms = new MemoryStream();
			var mw = new BinaryWriter(ms);
			SaveRecord(item, mw);
			var len = (int)ms.Length;
			
			RecordHeader rh;
			if (_records.TryGetValue(item, out rh))
			{
				if (rh.Size < len)
				{
					Free(rh);
					rh = Alloc(len);
					_records[item] = rh;
				}
			}
			else
			{
				rh = Alloc(len);
				_records[item] = rh;
			}
			
			rh.Used = len;
			rh.Status = RecordStatus.Item;
			Write(rh);
			var b = ms.GetBuffer();
			_stream.Write(b,0,(int)ms.Length);
			_stream.Flush();
		}
		
		public void Delete( T item )
		{
			RecordHeader rh;
			if (!_records.TryGetValue(item, out rh))
				return;
				
			Free(rh);
			_records.Remove(item);
			_stream.Flush();
		}
		
		RecordHeader Alloc(int len)
		{
				var rh = _firstRecord;
			var final = rh;
			while(rh != null)
			{
				final = rh;
				if (rh.Status == RecordStatus.Free && rh.Size >= len)
					return rh;
				rh = rh.Next;
			}

			rh = new RecordHeader();
			rh.Size = len;
			if (final != null)
			{
				rh.Position = final.Position + RecordHeader.StreamSize + final.Size;
				final.Next = rh;
				rh.Prev = final;
			}
			
			if (_firstRecord == null)
				_firstRecord = rh;
				
			return rh;
		}
		
		void Free(RecordHeader rh)
		{
			rh.Status = RecordStatus.Free;
			Write(rh);
		}
		
		void Write(RecordHeader rh)
		{
			_stream.Seek(rh.Position, SeekOrigin.Begin);
			rh.Write(_writer);
			//leave _stream in position for record
		}
		
		public IList<T> GetAllRecords()
		{
			var list = new List<T>();
			foreach (var record in _records)
				list.Add( record.Key );
				
			return list;
		}
		
		abstract protected T LoadRecord( BinaryReader r );
		abstract protected void SaveRecord( T record, BinaryWriter w );
	}
}
