using Uno;
using Uno.Collections;
using Uno.Testing;
using FuseTest;

namespace Fuse.Test
{
	public class ConcurrentCollectionTest : TestBase
	{
		int Sum( IEnumerable<int> list )
		{
			var c = 0;
			foreach( var i in list )
				c += i;
			return c;
		}
		
		[Test]
		public void Defer()
		{
			var l = new ConcurrentCollection<int>();
			l.Add(1);
			l.Add(2);
			l.Add(3);
			
			l.DeferChanges();
			Assert.IsTrue(l.Remove(3));
			Assert.IsFalse(l.Remove(4));
			Assert.IsFalse(l.Contains(3));
			
			l.Add(4);
			Assert.AreEqual(3, l.Count);
			Assert.IsTrue(l.Contains(4));

			//4 no in enumeration yet,3 still is
			Assert.AreEqual(6, Sum(l));
			l.EndDefer();
			
			Assert.IsTrue(l.Contains(4));
			Assert.IsFalse(l.Contains(3));
		}
		
		[Test]
		public void Using()
		{
			var l = new ConcurrentCollection<int>();
			l.Add(1);
			l.Add(2);

			using (var lk = l.DeferLock())
			{
				l.Add(3);
				l.Remove(2);
				Assert.AreEqual(3, Sum(l));
			}
			
			Assert.AreEqual(4, Sum(l));
		}
	}
}
