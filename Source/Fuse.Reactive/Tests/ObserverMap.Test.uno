using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ObserverMapTest : TestBase
	{
		[Test]
		public void Forward()
		{
			var rl = new ReadOnlyObservableList<Source>();
			var tm = new TestMap();
			tm.Attach(rl);
			
			rl.Add( new Source(5) );
			rl.Insert(0, new Source(3) );
			Assert.AreEqual( 2, tm.Length );
			Assert.AreEqual( 5, tm.Get(1).InitValue );
			Assert.AreEqual( 3, tm.Get(0).InitValue );
			
			rl.Replace(1, new Source(7));
			rl.RemoveAt(0);
			Assert.AreEqual( 1, tm.Length );
			Assert.AreEqual( 7, tm.Get(0).InitValue );
		}
		
	}
	
	class TestMap : ObserverMap<Mapped>
	{
		protected override Mapped Map(object v)
		{
			return new Mapped{ Backing = v, InitValue = ((Source)v).Value };
		}
		
		protected override object Unmap(Mapped mv)
		{
			return mv.Backing;
		}
	}
	
	class Source
	{
		public int Value;
		
		public Source( int value )
		{
			Value = value;
		}
	}
	
	class Mapped
	{
		public object Backing;
		public int InitValue;
	}
}
