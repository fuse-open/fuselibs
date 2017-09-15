using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ObserverMapTest : TestBase
	{
		[Test]
		public void Forward()
		{
			var rl = new ObservableList<Source>();
			var tm = new TestMap();
			tm.Attach(rl, null);
			
			rl.Add( new Source(5) );
			rl.Insert(0, new Source(3) );
			Assert.AreEqual( 2, tm.Count );
			Assert.AreEqual( 5, tm[1].InitValue );
			Assert.AreEqual( 3, tm[0].InitValue );
			
			rl.Replace(1, new Source(7));
			rl.RemoveAt(0);
			Assert.AreEqual( 1, tm.Count );
			Assert.AreEqual( 7, tm[0].InitValue );
			
			rl.Clear();
			Assert.AreEqual( 0, tm.Count );
			
			tm.Detach();
		}
		
		[Test]
		public void Backward()
		{
			var rl = new ObservableList<Source>();
			var tm = new TestMap();
			tm.Attach(rl, null);
			
			tm.Add( new Mapped{ InitValue = 4 } );
			Assert.AreEqual( 1, rl.Count );
			Assert.AreEqual( 4, rl[0].Value );
			
			tm.Insert( 0, new Mapped{ InitValue = 5 } );
			tm.Insert( 2, new Mapped{ InitValue = 2 } );
			tm.RemoveAt( 1 );
			Assert.AreEqual( 2, rl.Count );
			Assert.AreEqual( 5, rl[0].Value );
			Assert.AreEqual( 2, rl[1].Value );
			
			tm.Clear();
			Assert.AreEqual( 0, rl.Count );
			
			tm.Detach();
		}
		
		[Test]
		public void Both()
		{
			var rl = new ObservableList<Source>();
			var tm = new TestMap();
			tm.Attach(rl, null);
			
			rl.Add( new Source(1) ); // 1
			tm.Add( new Mapped{ InitValue = 2 } ); //1,2
			rl.Insert( 1, new Source(3) ); //1,3,2
			tm.Insert( 1, new Mapped { InitValue = 4 } ); //1,4,3,2
			Assert.AreEqual( 4, rl.Count );
			Assert.AreEqual( 4, tm.Count );
			var expect = new[]{ 1, 4, 3, 2 };
			for (int i=0; i < expect.Length; ++i)
			{
				Assert.AreEqual( expect[i], tm[i].InitValue );
				Assert.AreEqual( expect[i], rl[i].Value );
			}
			
			tm.Detach();
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
			if (mv.Backing == null)
				mv.Backing = new Source(mv.InitValue);
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
