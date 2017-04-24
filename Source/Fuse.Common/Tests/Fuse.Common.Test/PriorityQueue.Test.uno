using Uno;
using Uno.Collections;
using Uno.Testing;

using FuseTest;

namespace Fuse.Test
{
	class PQ { }
	
	public class PriorityQueueTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var a = new PQ();
			var b = new PQ();
			var c = new PQ();
			
			var l = new PriorityQueue<PQ>();
			Assert.IsTrue( l.Empty );
			l.Add(a,10);
			l.Add(b);
			l.Add(c,15);

			Assert.AreEqual(3,l.Count);
			Assert.AreEqual(b, l[0]);
			Assert.AreEqual(a, l[1]);
			Assert.AreEqual(c, l[2]);
			
			var p = l.PopTop();
			Assert.AreEqual(c,p);
			Assert.AreEqual(2,l.Count);
			Assert.AreEqual(b, l[0]);
			Assert.AreEqual(a, l[1]);

			l.Remove(b);
			Assert.AreEqual(1,l.Count);
			Assert.AreEqual(a, l[0]);
			Assert.IsFalse( l.Empty );
		}
		
		[Test]
		public void Fifo()
		{
			var l = new PriorityQueue<int>();
			l.Add(0, 100);
			l.Add(1, 200);
			l.Add(2, 200);
			Assert.AreEqual(1, l.PopTop());
		}
		
		[Test]
		public void Lifo()
		{
			var l = new PriorityQueue<int>(PriorityQueueType.Lifo);
			l.Add(0, 100);
			l.Add(1, 200);
			l.Add(2, 200);
			Assert.AreEqual(2, l.PopTop());
		}
		
		[Test]
		public void Float4Priority()
		{
			var a = new PQ();
			var b = new PQ();
			var c = new PQ();
			var d = new PQ();
			
			var l = new PriorityQueue<PQ>();
			Assert.IsTrue( l.Empty );
			l.Add(a,10);
			l.Add(b, float2(10,1));
			l.Add(c, float3(1,0,5) );
			l.Add(d, float4(1,0,5,-1) );

			Assert.AreEqual(4,l.Count);
			Assert.AreEqual(d, l[0]);
			Assert.AreEqual(c, l[1]);
			Assert.AreEqual(a, l[2]);
			Assert.AreEqual(b, l[3]);
		}
	}
}
