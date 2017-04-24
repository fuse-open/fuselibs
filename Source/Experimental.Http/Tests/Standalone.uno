using Uno;
using Uno.Testing;

using Fuse;

using Experimental.Cache;

public class App : TestRunnerApp
{
	public App()
	{
		Add( new BasicTest() );
		Add( new CountTest() );
	}
}

abstract class DiskCacheTest : TestCase
{
	protected DiskCache DC;
	
	protected string DirectoryName = "testCacheDir";
	
	public override void Setup()
	{
		if (Uno.IO.Directory.Exists(DirectoryName))
			Uno.IO.Directory.Delete(DirectoryName, true);
			
		DC = new DiskCache(DirectoryName, DiskCache.DirectoryType.Absolute);
	}
	
	protected void Reload()
	{
		DC.Dispose();
		DC = new DiskCache(DirectoryName, DiskCache.DirectoryType.Absolute);
	}
	
	public override void Teardown()
	{
		DC.Dispose();
		DC = null;
	}
	
	protected void GenRecord(string name, int len)
	{
		var b = new byte[len];
		for (int i=0; i<len; ++i)
			b[i] = (byte)i;
			
		var r = DC.CreateRecord(name);
		r.AddMeta( "Len", "" + len );
		r.Stream.Write(b, 0, b.Length);
		r.Close();
	}
}

class BasicTest : DiskCacheTest
{
	public override void Run()
	{
		var r = DC.CreateRecord( "one" );
		r.AddMeta( "ETag", "123" );
		
		var data = new byte[]{ 0,1,2,3,4,5,6,7,8,9 };
		r.Stream.Write( data, 0, data.Length );
		r.Close();
		
		LoadTests();

		Reload();
		
		LoadTests();
		Done();
	}
	
	void LoadTests()
	{
		var l = DC.LoadRecord( "one", OnLoaded );
		Assert.IsTrue( l );
	}
	
	void OnLoaded( ICacheReader r )
	{
		Assert.AreEqual( 10, r.DataSize );
		Assert.AreEqual( "123", r.GetMeta( "ETag" ) );
		
		var data = new byte[(int)r.DataSize];
		r.Stream.Read(data,0,data.Length);
		Assert.AreEqual( new byte[]{ 0,1,2,3,4,5,6,7,8,9 }, data );
	}
}

class CountTest : DiskCacheTest
{
	public override void Run()
	{
		Assert.AreEqual( 0, DC.RecordCount );
		for (int i=0; i < 50; ++i)
			GenRecord("R" + i, i*10);

		Assert.AreEqual( 50, DC.RecordCount );
		Reload();
		Assert.AreEqual( 50, DC.RecordCount );
		
		DC.Clear();
		Assert.AreEqual( 0, DC.RecordCount );
		Reload();
		Assert.AreEqual( 0, DC.RecordCount );
		
		Done();
	}
}
