using Uno;
using Uno.Testing;

using Fuse.Internal;

using FuseTest;

namespace Fuse.Test
{
	public class MiniListTest : TestBase
	{
		void AddNull()
		{
			var list = new MiniList<string>();
			list.Add(null);
		}

		[Test]
		public void Add()
		{
			Assert.Throws<ArgumentNullException>(AddNull);
		}

		void InsertNull()
		{
			var list = new MiniList<string>();
			list.Insert(0, null);
		}

		[Test]
		public void Insert()
		{
			Assert.Throws<ArgumentNullException>(InsertNull);

			var list = new MiniList<string>();
			list.Insert(0, "bar");
			Assert.AreCollectionsEqual(new string[]{ "bar" }, list);
			Assert.AreEqual(1, list.Count);
			
			list.Insert(0, "foo");
			list.Insert(2, "baz");
			Assert.AreCollectionsEqual(new string[]{ "foo", "bar", "baz" }, list);
		}
		
		void InsertAt1()
		{
			var list = new MiniList<Dummy>();
			list.Insert(1, new Dummy());
		}
		
		[Test]
		public void ThrowInsertAt()
		{
			Assert.Throws<ArgumentOutOfRangeException>(InsertAt1);
		}

		[Test]
		public void Remove()
		{
			var list = new MiniList<string>() { "foo", "bar" };
			Assert.IsTrue(list.Remove("foo"));
			Assert.IsFalse(list.Remove("foo"));
			Assert.IsTrue(list.Remove("bar"));
			Assert.IsFalse(list.Remove("bar"));
		}

		[Test]
		public void RemoveAt()
		{
			var list = new MiniList<string>() { "foo", "bar", "baz" };

			list.RemoveAt(1);
			Assert.AreCollectionsEqual(new string[]{ "foo", "baz" }, list);
			list.RemoveAt(1);
			Assert.AreCollectionsEqual(new string[]{ "foo" }, list);
			list.RemoveAt(0);
			Assert.AreEqual(0, list.Count);
		}

		[Test]
		public void Empty()
		{
			var list = new MiniList<string>();
			Assert.AreEqual(0, list.Count);

			Assert.IsFalse(list.Contains("one"));
			Assert.IsFalse(list.Contains(null));
			Assert.IsFalse(list.Remove(null));
		}

		[Test]
		public void One()
		{
			var list = new MiniList<string>();

			for (int i=0; i < 3; ++i)
			{
				list.Add("one");
				Assert.AreEqual(1, list.Count);
				Assert.IsTrue(list.Contains("one"));
				Assert.IsTrue(list.Contains("stone".Substring(2))); //ensure it's not object equality, but value equality
				Assert.IsFalse(list.Contains("two"));
				Assert.AreEqual("one", list[0]);

				list.Remove("stone".Substring(2)); // remove should use value equality
				Assert.AreEqual(0, list.Count);
			}
		}

		[Test]
		public void Multiple()
		{
			var list = new MiniList<string>();

			list.Add("one");
			list.Add("two");
			list.Add("three");

			Assert.AreEqual(3, list.Count);
			Assert.IsTrue(list.Contains("two"));
			Assert.IsTrue(list.Contains("andtwo".Substring(3))); //ensure it's not object equality, but value equality
			Assert.IsFalse(list.Contains("four"));
			Assert.AreEqual("three", list[2]);

			list.Remove("two");
			Assert.AreEqual(2, list.Count);
			Assert.AreEqual("three", list[1]);

			list.Clear();
			Assert.AreEqual(0, list.Count);
		}

		class Dummy {}
		
		[Test]
		public void ObjectContains()
		{
			var list = new MiniList<object>();
			
			var a = new Dummy();
			var b = new Dummy();
			
			list.Add(a);
			Assert.IsTrue(list.Contains(a));
			list.Add(b);
			Assert.IsTrue(list.Contains(b));
		}
		
		[Test]
		public void IterateSimple()
		{
			var list = new MiniList<string>();
			list.Add("1");
			list.Add("2");
			list.Add("3");
			
			var iter = list.GetEnumeratorVersionedStruct();
			Assert.AreEqual("1,2,3", Join(ref iter));
		}
		
		[Test]
		//the behavior of the ObjectList versioning is more fully tested in the ObjectList code
		public void IterateVersion()
		{
			var list = new MiniList<string>();
			var it0 = list.GetEnumeratorVersionedStruct();
			
			list.Add("1");
			var it1 = list.GetEnumeratorVersionedStruct();
			
			list.Add("2");
			list.Add("3");
			var it2 = list.GetEnumeratorVersionedStruct();
			
			list.RemoveAt(0);
			var it3 = list.GetEnumeratorVersionedStruct();
			
			Assert.AreEqual("", Join(ref it0));
			Assert.AreEqual("1",Join(ref it1));
			Assert.AreEqual("1,2,3",Join(ref it2));
			Assert.AreEqual("2,3",Join(ref it3));
		}
		
		[Test]
		//ensures it'd being properly disposed of
		public void Foreach()
		{
			var l = new MiniList<string>();
			l.Add("he");
			l.Add("llo");
			
			string c ="";
			foreach( var d in l )
				c += d;
				
			Assert.AreEqual("hello",c);
			//Assert.IsTrue(l.TestIsConsistent);
		}
		
		
		string Join( ref MiniList<string>.Enumerator iter )
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
		
	}
}
