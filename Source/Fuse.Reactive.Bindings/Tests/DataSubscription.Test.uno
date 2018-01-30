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
		
		[Test]
		//covers the deprecated support for {} bindings
		public void Deprecated()
		{
			var p = new UX.DataSubscription.Deprecated();
			using (var dg = new RecordDiagnosticGuard())
			{
				try
				{
					using (var root = TestRootPanel.CreateWithChild(p))
					{
						root.StepFrameJS();
						Assert.AreEqual( "hi", p.a.Value );
						Assert.AreEqual( "1", GetText(p.b));
						Assert.AreEqual( "2", GetText(p.c));
						Assert.AreEqual( "3,4", GetText(p.d));
					}
				}
				finally
				{
					var dm = dg.DequeueAll();
					foreach (var d in dm) 
						Assert.IsTrue( d.Message.IndexOf( "deprecated" ) != -1 );
				}
			}
		}
	}
}
