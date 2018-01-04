using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Bindings.Test
{
	public class DataSubscriptionTest : TestBase
	{
		[Test]
		public void Minimal()
		{
			var p = new UX.DataSubscription.Minimal();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "hi", p.txt.Value );
			}
		}
		
		[Test]
		public void Cascade()
		{
			var p = new UX.DataSubscription.Cascade();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "1", p.a1.Value );
				Assert.AreEqual( "B", p.b1.Value );
				Assert.AreEqual( "2", p.a2.Value );
				Assert.AreEqual( "B", p.b2.Value );
			}
		}
	}
}
