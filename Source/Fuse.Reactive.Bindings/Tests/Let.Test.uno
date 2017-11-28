using Uno;
using Uno.Testing;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class LetTest : TestBase
	{
		[Test]
		public void Explicit()
		{
			var p = new UX.Let.Explicit();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(2, p.d.Value);
				Assert.AreEqual(2, p.e.Value);
				Assert.AreEqual(7, p.f.Value);
				Assert.AreEqual(7, p.g.Value);
				
				p.a.Value = 3;
				root.PumpDeferred();
				Assert.AreEqual(3, p.d.Value);
				Assert.AreEqual(3, p.e.Value);
				
				p.set.Pulse();
				root.StepFrame();
				Assert.AreEqual(4, p.d.Value);
				Assert.AreEqual(4, p.e.Value);
			}
		}
		
		[Test]
		public void SimpleBind()
		{
			var p = new UX.Let.SimpleBind();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(51, p.d.Value);
				
				p.slider.Value = 3;
				root.PumpDeferred();
				Assert.AreEqual(4, p.d.Value);
			}
		}

		[Test]
		//tests interactions with JS Observable (ensures they are passed-thru/handled naturally)
		public void Observable()
		{
			var p = new UX.Let.Observable();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				
				Assert.AreEqual(2, p.d.Value);
				Assert.AreEqual(2, p.dp.Value);
				Assert.AreEqual("3,2,1", GetDudZ(p.e));
				Assert.AreEqual("3,2,1", GetDudZ(p.ep));
				
				p.callStep1.Perform();
				root.StepFrameJS();
				Assert.AreEqual(3, p.d.Value);
				Assert.AreEqual(3, p.dp.Value);
				Assert.AreEqual("4,3,2,1", GetDudZ(p.e));
				Assert.AreEqual("4,3,2,1", GetDudZ(p.ep));
			}
		}
		
		[Test]
		public void TwoWayProperty()
		{
			var p = new UX.Let.TwoWayProperty();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "init", p.inner.t.Value );
				Assert.AreEqual( "init", p.inner.pt.Value );
				Assert.AreEqual( "init", p.inner.lTitle.Value );
				Assert.AreEqual( "init", p.inner.title );
				
				p.inner.set.Pulse();
				root.StepFrame();
				Assert.AreEqual( "flip", p.inner.t.Value );
				Assert.AreEqual( "flip", p.inner.pt.Value );
				Assert.AreEqual( "flip", p.inner.lTitle.Value );
				Assert.AreEqual( "flip", p.inner.title );
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-public/issues/740")]
		public void Array()
		{
			var p = new UX.Let.Array();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "5,4,3,2,1", GetDudZ(p));
			}
		}
		
		[Test]
		public void ExpressionChain()
		{
			var p = new UX.Let.ExpressionChain();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 5, p.oc.Value );
				
				p.set.Pulse();
				root.StepFrame();
				Assert.AreEqual( 7, p.oc.Value );
			}
		}
		
		[Test]
		public void Null()
		{
			var p = new UX.Let.Null();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( false, p.ha.BoolValue );
				Assert.AreEqual( false, p.hb.BoolValue );
				Assert.AreEqual( true, p.hc.BoolValue ); //can't be undefiend due to `Property` binding
				Assert.AreEqual( false, p.hd.BoolValue );
				
				p.d.Value = null;
				p.nl.Value = p.nb.Value;
				root.PumpDeferred();
				Assert.AreEqual( true, p.ha.BoolValue );
				Assert.AreEqual( true, p.hc.BoolValue );
				Assert.AreEqual( true, p.hd.BoolValue );
			}
		}
	}
}
