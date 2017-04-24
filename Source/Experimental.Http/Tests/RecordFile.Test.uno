using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.Testing;

using Experimental.Cache;
using FuseTest;

namespace Experimental.Cache.Test
{
	class TestRecord
	{
		public int Id;
		public int Value;
	}
	
	class TestRecordFile : RecordFile<TestRecord>
	{
		public TestRecordFile( string filename ) : base(filename) { }
		
		//a simple tally format to have records of variable size
		protected override TestRecord LoadRecord( BinaryReader r )
		{
			var tr = new TestRecord();
			tr.Id = r.ReadInt();
			while (true)
			{
				var a = r.ReadByte();
				if (a == 0)
					break;
				tr.Value++;
			}
			
			return tr;
		}
		
		protected override void SaveRecord( TestRecord record, BinaryWriter w )
		{
			w.Write(record.Id);
			for (int i=0; i < record.Value; ++i)
				w.Write( (byte)1 );
			w.Write( (byte)0);
		}
	}

	class RecordTester
	{
		public string Filename;
		public TestRecordFile Turf;
		
		public RecordTester(string filename)
		{
			Filename = filename;
			if (File.Exists(Filename))
				File.Delete(Filename);
			Turf = new TestRecordFile( Filename );
		}
		
		public Random Rand = new Random(123);
		public Dictionary<int,TestRecord> Records = new Dictionary<int,TestRecord>();
		public void AddRecords(int count)
		{
			for (int i=0; i < count; ++i)
			{
				int id = Rand.NextInt();
				while (Records.ContainsKey(id))
					id = Rand.NextInt();
					
				var record = new TestRecord();
				record.Id = id;
				record.Value = Rand.NextInt() % 100;
				
				Turf.Update(record);
				Records[id] = record;
			}
		}
		
		public void ModifyRecords(int count)
		{
			var list = new List<TestRecord>();
			foreach (var r in Records)
				list.Add(r.Value);
				
			for (int i=0; i < count; ++i)
			{
				var n = Rand.NextInt(list.Count);
				var record = list[n];
				list.RemoveAt(n);
				record.Value = Rand.NextInt() % 100;
				Turf.Update(record);
			}
		}
		
		public void DeleteRecords(int count)
		{
			var list = new List<TestRecord>();
			foreach (var r in Records)
				list.Add(r.Value);
				
			for (int i=0; i < count; ++i)
			{
				var n = Rand.NextInt(list.Count);
				var record = list[n];
				list.RemoveAt(n);
				Turf.Delete(record);
				Records.Remove(record.Id);
			}
		}
		
		public void Reload()
		{
			Turf.Close();
			Turf = new TestRecordFile( Filename );
			CompareRecords();
		}
		
		public void CompareRecords()
		{
			var all = Turf.GetAllRecords();
			Assert.AreEqual( Records.Count, all.Count );
			foreach (var record in all)
				Assert.AreEqual(record.Value, Records[record.Id].Value);
		}
	}
	
	public class RecordFileTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var rt = new RecordTester("basic.rfile");
			rt.AddRecords(50);
			rt.Reload();
			rt.Reload();
		}
		
		[Test]
		public void Modify()
		{
			var rt = new RecordTester( "modify.rfile" );
			rt.AddRecords(47);
			rt.ModifyRecords(10);
			rt.CompareRecords();
			rt.Reload();
		}
		
		[Test]
		public void Delete()
		{
			var rt = new RecordTester( "delete.rfile" );
			rt.AddRecords(53);
			rt.DeleteRecords(10);
			rt.CompareRecords();
			rt.Reload();
		}
		
		[Test]
		public void Combo()
		{
			var rt = new RecordTester( "combo.rfile" );
			for( int i=0; i < 100; ++i)
			{
				int c=  rt.Rand.NextInt(50);
				rt.AddRecords(c);
				rt.ModifyRecords(c/3);
				rt.DeleteRecords(c/2);
				rt.CompareRecords();
			}
			
			rt.Reload();
			//intentional duplicate, checks rewriting on load
			rt.Reload();
		}
	}
}
