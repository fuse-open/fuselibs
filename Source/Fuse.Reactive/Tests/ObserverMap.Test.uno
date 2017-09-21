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
		
		[Test]
		//tests some basic behaviour of ObserverMap, including that which isn't easy to detect at a higher level
		public void Slave()
		{
			var rl = new ObservableList<Source>();
			var tm = new TestMap();
			var slave = new ObserverSlave();
			tm.Attach(rl, slave);
			
			//Attach should not genereate any callback
			Assert.AreEqual( "", slave.Trace );
			
			rl.Add( new Source(1) );
			rl.Insert( 1, new Source(2) );
			rl.RemoveAt( 0 );
			rl.Clear();
			Assert.AreEqual( "AI@1R@0C", slave.Trace );
		}
	}
	
	//minimal sanity test
	class ObserverSlave : IObserver
	{
		public string Trace = "";
		
		void IObserver.OnClear()
		{
			Trace += "C";
		}

		void IObserver.OnNewAll(IArray values)
		{
			Trace += "NA" + values.Length;
		}
		
		void IObserver.OnNewAt(int index, object newValue)
		{
			Trace += "N@" + index;
		}
		
		void IObserver.OnSet(object newValue)
		{
			Trace += "S";
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			Trace += "A";
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			Trace += "R@" + index;
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			Trace += "I@" + index;
		}
		
		void IObserver.OnFailed(string message)
		{
			Trace += "F";
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
