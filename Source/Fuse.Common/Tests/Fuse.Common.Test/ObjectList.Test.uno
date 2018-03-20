using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Internal;

using FuseTest;

namespace Fuse.Test
{
	public class ObjectListTest : TestBase
	{
		class Dummy
		{
			static int Count = 0;
			public int Value;
			
			public Dummy()
			{
				Value = Count++;
			}
			
			public Dummy(int ndx)
			{
				Value = ndx;
			}
			
			public override string ToString()
			{
				return "#" + Value;
			}
		}
					
		[Test]
		public void Basic()
		{
			var l = new ObjectList<Dummy>();
			Assert.AreEqual(0,l.Count);
			
			var a = new Dummy();
			l.Add(a);
			Assert.AreEqual(1,l.Count);
			Assert.AreEqual(a, l[0]);
			
			var b = new Dummy();
			l.Add(b);
			Assert.AreEqual(2,l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.AreEqual(b, l[1]);
			
			//force a grow
			for (int i=0; i < ObjectList<Dummy>.InitialCapacity; ++i)
				l.Add( new Dummy() );
			Assert.AreEqual(2 + ObjectList<Dummy>.InitialCapacity,l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.AreEqual(b, l[1]);
			
			var c = new Dummy();
			l.Insert(0,c);
			Assert.AreEqual(3 + ObjectList<Dummy>.InitialCapacity,l.Count);
			Assert.AreEqual(c, l[0]);
			Assert.AreEqual(a, l[1]);
			Assert.AreEqual(b, l[2]);
			
			var d = new Dummy();
			l.Insert(1,d);
			Assert.AreEqual(4 + ObjectList<Dummy>.InitialCapacity,l.Count);
			Assert.AreEqual(c, l[0]);
			Assert.AreEqual(d, l[1]);
			Assert.AreEqual(a, l[2]);
			Assert.AreEqual(b, l[3]);
			
			Assert.IsTrue(l.Contains(a));
			Assert.IsTrue(l.Remove(a));
			Assert.IsFalse(l.Contains(a));
			Assert.AreEqual(3 + ObjectList<Dummy>.InitialCapacity,l.Count);
			Assert.AreEqual(c, l[0]);
			Assert.AreEqual(d, l[1]);
			Assert.AreEqual(b, l[2]);
			
			Assert.IsTrue(l.Contains(d));
			l.RemoveAt(1);
			Assert.IsFalse(l.Contains(d));
			Assert.AreEqual(2 + ObjectList<Dummy>.InitialCapacity,l.Count);
			Assert.AreEqual(c, l[0]);
			Assert.AreEqual(b, l[1]);
			
			l.Clear();
			Assert.AreEqual(0, l.Count);
			Assert.IsFalse(l.Contains(c));
			Assert.IsFalse(l.Contains(b));
			
			Assert.IsTrue(l.TestIsConsistent);
		}
		
		[Test]
		public void TailOps()
		{
			var l = new ObjectList<Dummy>();
			var a = new Dummy();
			var b = new Dummy();
			var c = new Dummy();
			l.Insert(0, a);
			l.Insert(1, b);
			l.Insert(2, c);
			
			Assert.AreEqual(3, l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.AreEqual(b, l[1]);
			Assert.AreEqual(c, l[2]);
			
			l.RemoveAt(2);
			Assert.AreEqual(2, l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.AreEqual(b, l[1]);
			Assert.IsFalse(l.Contains(c));
			
			l.Remove(b);
			Assert.AreEqual(1, l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.IsFalse(l.Contains(b));
			
			l.RemoveAt(0);
			Assert.AreEqual(0, l.Count);
			Assert.IsFalse(l.Contains(a));
			
			Assert.IsTrue(l.TestIsConsistent);
		}
		
		[Test]
		public void HeadOps()
		{
			var l = new ObjectList<Dummy>();
			var a = new Dummy();
			var b = new Dummy();
			var c = new Dummy();
			l.Insert(0, a);
			l.Insert(0, b);
			l.Insert(0, c);
			
			Assert.AreEqual(3, l.Count);
			Assert.AreEqual(a, l[2]);
			Assert.AreEqual(b, l[1]);
			Assert.AreEqual(c, l[0]);
			
			l.RemoveAt(0);
			Assert.AreEqual(2, l.Count);
			Assert.AreEqual(a, l[1]);
			Assert.AreEqual(b, l[0]);
			Assert.IsFalse(l.Contains(c));
			
			l.Remove(b);
			Assert.AreEqual(1, l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.IsFalse(l.Contains(b));
			
			l.RemoveAt(0);
			Assert.AreEqual(0, l.Count);
			Assert.IsFalse(l.Contains(a));
			
			Assert.IsTrue(l.TestIsConsistent);
		}
		
		[Test]
		//random critical path check, compare against known implementation
		public void Random()
		{
			var r = new Random(1234);
			
			var ol = new ObjectList<Dummy>();
			var refList = new List<Dummy>();
			
			var init = new Dummy();
			ol.Add(init);
			refList.Add(init);
			
			for (int i=0; i < 100; ++i )
			{
				var d1 = new Dummy();
				var d2 = new Dummy();
				var n = r.Next(refList.Count);
				refList.Insert(n, d1);
				ol.Insert(n, d1);
				refList.Add(d2);
				ol.Add(d2);
				
				n = r.Next(refList.Count);
				refList.RemoveAt(n);
				ol.RemoveAt(n);
			}
			
			Assert.AreEqual(refList.Count, ol.Count);
			for (int i=0; i < refList.Count; ++i)
				Assert.AreEqual(refList[i],ol[i]);
				
			Assert.IsTrue(ol.TestIsConsistent);
		}
		
		[Test]
		public void Error()
		{
			var et = new ErrorTest();
			Assert.Throws<ArgumentOutOfRangeException>(et.InsertNeg);
			Assert.Throws<ArgumentOutOfRangeException>(et.InsertOver);
			Assert.Throws<ArgumentOutOfRangeException>(et.RemoveNeg);
			Assert.Throws<ArgumentOutOfRangeException>(et.RemoveOver);
			Assert.Throws<ArgumentOutOfRangeException>(et.IndexNeg);
			Assert.Throws<ArgumentOutOfRangeException>(et.IndexOver);
		}
		
		class ErrorTest
		{
			ObjectList<Dummy> _list = new ObjectList<Dummy>();
			
			public ErrorTest()
			{
				_list.Add(new Dummy());
			}
			
			public void InsertNeg() { _list.Insert(-1, new Dummy() ); }
			public void InsertOver() { _list.Insert(_list.Count+1, new Dummy() ); }
			public void RemoveNeg() { _list.RemoveAt(-1); }
			public void RemoveOver() { _list.RemoveAt(_list.Count+1); }
			public void IndexNeg() { Ignore(_list[-1]); }
			public void IndexOver() { Ignore(_list[_list.Count+1]); }
			
			void Ignore(object q) {} 
		}
		
		ObjectList<Dummy> CreateDummyList(int size)
		{
			var l = new ObjectList<Dummy>();
			for (int i=0; i < size; ++i)
				l.Add( new Dummy(i) );
			return l;
		}
		
		[Test] 
		public void Enumerator()
		{
			var l = CreateDummyList(100);
				
			var c = 0;
			foreach (var d in l)
			{
				Assert.AreEqual(l[c], d);
				c++;
			}
		}
		
		[Test]
		public void Iterator()
		{
			var l = CreateDummyList(100);
			var cp = l.ToArray();
			var c = 0;
			using (var iter = l.GetEnumeratorVersionedStruct())
			{
				while (iter.MoveNext())
				{
					Assert.AreEqual(cp[c], iter.Current);
					c++;
				}
			}
			
			Assert.AreEqual(100,c);
		}
		
		[Test]
		public void LockedIterate1()
		{
			var r = new Random(1234);
			var l = CreateDummyList(100);
			var cp = l.ToArray();
			Assert.AreEqual(100,cp.Length);
			
			var c = 0;
			using (var iter = l.GetEnumeratorVersionedStruct())
			{
				for (int i=0; i < 20; ++i)
					l.RemoveAt( r.Next(l.Count));
					
				//iter still sees the list prior to the removed items
				while (iter.MoveNext())
				{
					Assert.AreEqual(cp[c], iter.Current);
					c++;
				}
			}
			
			Assert.AreEqual(100,c);
		}
		
		[Test]
		public void LockedIterate2()
		{
			var l = CreateDummyList(10);
			var cp0 = l.ToArray();
			var it0 = l.GetEnumeratorVersionedStruct();
			
			l.RemoveAt(5); //0,1,2,3,4,6,7,8,9
			l.RemoveAt(0); //1,2,3,4,6,7,8,9
			
			var cp1 = l.ToArray();
			var it1 = l.GetEnumeratorVersionedStruct();
			
			l.RemoveAt(5); //1,2,3,4,6,8,9
			l.RemoveAt(5); //1,2,3,4,6,9
			
			Assert.AreEqual(6, l.Count);
			Assert.AreEqual(cp0[1], l[0]);
			Assert.AreEqual(cp0[9], l[5]);

			var cp2 = l.ToArray();
			var it2 = l.GetEnumeratorVersionedStruct();
			
			l.Add(new Dummy(12)); //1,2,3,4,6,9,12
			Assert.AreEqual(7, l.Count);
			Assert.AreEqual(12, l[6].Value);
			
			l.Insert(0, new Dummy(10)); //10,1,2,3,4,6,9,12
			l.Insert(2, new Dummy(11)); //10,1,11,2,3,4,6,9,12
			
			var cp3 = l.ToArray();
			var it3 = l.GetEnumeratorVersionedStruct();
			
			Assert.AreEqual(9, l.Count);
			Assert.AreEqual(10, l[0].Value);
			Assert.AreEqual(11, l[2].Value);
			Assert.AreEqual(12, l[8].Value);
			
			Assert.AreEqual("#0,#1,#2,#3,#4,#5,#6,#7,#8,#9", Join(ref it0));
			Assert.AreEqual("#1,#2,#3,#4,#6,#7,#8,#9", Join(ref it1));
			Assert.AreEqual("#1,#2,#3,#4,#6,#9", Join(ref it2));
			Assert.AreEqual("#10,#1,#11,#2,#3,#4,#6,#9,#12", Join(ref it3));
			
			Assert.AreEqual("#0,#1,#2,#3,#4,#5,#6,#7,#8,#9", Join(cp0));
			Assert.AreEqual("#1,#2,#3,#4,#6,#7,#8,#9", Join(cp1));
			Assert.AreEqual("#1,#2,#3,#4,#6,#9", Join(cp2));
			Assert.AreEqual("#10,#1,#11,#2,#3,#4,#6,#9,#12", Join(cp3));
			
			//also checks that the lock level is 0
			Assert.IsTrue(l.TestIsConsistent);
			
			var cp4 = l.ToArray();
			var it4 = l.GetEnumeratorVersionedStruct();
			Assert.AreEqual("#10,#1,#11,#2,#3,#4,#6,#9,#12", Join(ref it4));
			Assert.AreEqual("#10,#1,#11,#2,#3,#4,#6,#9,#12", Join(cp4));
		}
		
		
		[Test]
		//ensures it'd being properly disposed of
		public void Foreach()
		{
			var l = new ObjectList<Dummy>();
			var a = new Dummy(5);
			var b = new Dummy(6);
			l.Add(a);
			l.Add(b);
			
			int c =0;
			foreach( var d in l )
				c += d.Value;
				
			Assert.AreEqual(11,c);
			
			Assert.AreEqual(0, l.UsingIndexOf(a));
			Assert.AreEqual(1, l.ForeachIndexOf(b));
			
			Assert.IsTrue(l.TestIsConsistent);
		}
		
		string Join( ref ObjectList<Dummy>.Enumerator iter )
		{
			string c = "";
			while (iter.MoveNext())
			{
				if (c != "")
					c += ",";
				c += iter.Current;
			}
			
			iter.Dispose();
			return c;
		}
		
		string Join( Dummy[] items )
		{
			string c = "";
			for (int i=0; i < items.Length; ++i)
			{
				if (i > 0)
					c += ",";
				c += items[i];
			}
			return c;
		}
	}
	
	static class TestExtensions
	{
        public static int UsingIndexOf<T>(this IEnumerable<T> self, T element)
        {
            int i = 0;
            using (var iter = self.GetEnumerator())
            {
				while (iter.MoveNext())
				{
					if (iter.Current.Equals(element))
						return i;
					i++;
				}
            }
            return -1;
        }
        
        public static int ForeachIndexOf<T>(this IEnumerable<T> self, T element)
        {
            int i = 0;
            foreach (var item in self)
            {
                if (item.Equals(element))
                    return i;
                i++;
            }
            return -1;
        }
        
	}
}