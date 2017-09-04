using Fuse;
using FuseTest;
using Uno;
using Uno.Testing;

namespace Fuse.Test
{
	class TypeA {}
	class TypeB {}
	
	class Counter
	{
		public int Value;
		
		public Counter() {}
		public Counter( int value ) { Value = value; }
		
		static public void Add( object value, object state )
		{
			if (value is Counter)
				((Counter)state).Value += ((Counter)value).Value;	
			else
				((Counter)state).Value += (int)value;
		}
	}
	
	public class PropertiesTest : TestBase
	{
		static PropertyHandle handleA = Properties.CreateHandle();
		static PropertyHandle handleB = Properties.CreateHandle();
		static PropertyHandle handleC = Properties.CreateHandle();
		
		[Test]
		public void Basic()
		{
			var props = new Properties();
			
			var objA = new TypeA();
			var objB = new TypeB();
			
			props.Set(handleA, 1);
			props.Set(handleB, objA);
			props.Set(handleC, objB);
			
			Assert.AreEqual( 1, props.Get(handleA) );
			Assert.AreEqual( objA, props.Get(handleB) );
			Assert.AreEqual( objB, props.Get(handleC) );
			
			object value;
			Assert.IsTrue( props.TryGet(handleA, out value) );
			Assert.AreEqual( 1, value );
			Assert.IsTrue( props.TryGet(handleB, out value) );
			Assert.AreEqual( objA, value );
		}
		
		[Test]
		public void NotFound()
		{
			var props = new Properties();
			
			object value;
			Assert.IsFalse( props.TryGet(handleA, out value) );
			
			props.Set(handleB, 123);
			Assert.IsFalse( props.TryGet(handleA, out value) );
			
			props.Set(handleA, 1);
			props.Clear(handleA);
			Assert.IsFalse( props.TryGet(handleA, out value) );

			props.Clear(handleB);
			Assert.IsFalse( props.TryGet(handleA, out value) );
		}
		
		[Test]
		public void List()
		{
			var pa = new Properties();
			pa.AddToList( handleA, 1 );
			pa.AddToList( handleB, 2 );
			pa.AddToList( handleA, 10 );
			pa.Set( handleC, 3 );
			pa.AddToList( handleA, 100 );
			pa.AddToList( handleA, 1000 );
			pa.AddToList( handleA, 100 );

			var c = new Counter();
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1211, c.Value );
			
			c.Value = 0;
			pa.RemoveFromList( handleA, 100);
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1111, c.Value );
			
			pa.Clear( handleB );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1111, c.Value );
			
			pa.AddToList( handleA, 100 );
			pa.RemoveAllFromList( handleA, 100 );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1011, c.Value );
			
			pa.Clear( handleA );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 0, c.Value );
			
			Assert.AreEqual( 3, (int)pa.Get(handleC) );
		}
		
		[Test]
		public void ListUnboxed()
		{
			var v1 = new Counter(1);
			var v10 = new Counter(10);
			var v2 = new Counter(2);
			var v3 = new Counter(3);
			var v100 = new Counter(100);
			var v1000 = new Counter(1000);
			
			var pa = new Properties();
			pa.AddToList( handleA, v1 );
			pa.AddToList( handleB, v2 );
			pa.AddToList( handleA, v10 );
			pa.Set( handleC, v3 );
			pa.AddToList( handleA, v100 );
			pa.AddToList( handleA, v1000 );
			pa.AddToList( handleA, v100 );

			var c = new Counter();
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1211, c.Value );
			
			c.Value = 0;
			pa.RemoveFromList( handleA, v100);
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1111, c.Value );
			
			pa.Clear( handleB );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1111, c.Value );
			
			pa.AddToList( handleA, v100 );
			pa.RemoveAllFromList( handleA, v100 );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 1011, c.Value );
			
			pa.Clear( handleA );
			c.Value = 0;
			pa.ForeachInList( handleA, Counter.Add, c );
			Assert.AreEqual( 0, c.Value );
			
			Assert.AreEqual( 3, ((Counter)pa.Get(handleC)).Value );
		}
	}
	
}
