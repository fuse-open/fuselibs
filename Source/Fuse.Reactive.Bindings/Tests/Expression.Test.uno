using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Bindings.Test
{
	public class ExpressionTest : TestBase
	{
		[Test]
		public void Property()
		{
			var p = new UX.Expression.Property();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.T1.Y);
				Assert.AreEqual(0,p.T2.Y);
				
				p.S1.Value = 50;
				root.PumpDeferred();
				Assert.AreEqual(-50,p.T1.Y);
				
				p.S2.Progress = 0.7f;
				root.PumpDeferred();
				Assert.AreEqual(-0.7f,p.T2.Y);
			}
		}
				
		[Test]
		public void PropertyTriggerProgress()
		{
			var p = new UX.Expression.PropertyTriggerProgress();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.T3.Y);
				
				p.S3.Value = true;
				root.PumpDeferred();
				Assert.AreEqual(1,p.T3.Y);
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-private/issues/3806")]
		public void Anchor()
		{
			var p = new UX.Expression.Anchor();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();

				//UNO: https://github.com/fusetools/uno/issues/1055
				var x = p.P.Anchor.X;
				var y = p.P.Anchor.Y;
				Assert.AreEqual( 50, x.Value );
				Assert.AreEqual( 50, y.Value );
				Assert.AreEqual( Unit.Percent, x.Unit );
				Assert.AreEqual( Unit.Percent, y.Unit );
			}
		}
		
		[Test]
		public void Null()
		{
			var p = new UX.Expression.Null();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//should start without values since none available yet
				Assert.AreEqual( null, p.staticNull.ObjectValue );
				Assert.AreEqual( null, p.emptyFloat.ObjectValue );
				Assert.AreEqual( null, p.structNone.ObjectValue );
				Assert.AreEqual( 5, p.structCoal.Value );
				Assert.AreEqual( 6, p.emptyCoal.Value );
				
				root.StepFrameJS();
				Assert.AreEqual( null, p.staticNull.ObjectValue );
				Assert.AreEqual( null, p.emptyFloat.ObjectValue );
				Assert.AreEqual( null, p.structNone.ObjectValue );
				Assert.AreEqual( 5, p.structCoal.Value );
				Assert.AreEqual( 6, p.emptyCoal.Value );
				
				p.callStep1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 0, p.emptyFloat.Value );
				Assert.AreEqual( 0, p.emptyCoal.Value );
				Assert.AreEqual( 3, p.structNone.Value );
				Assert.AreEqual( 3, p.structCoal.Value );
				
				p.callStep2.Perform();
				root.StepFrameJS();
				//as these are `float` types there is no way to revert them to a previous "null" state
				Assert.AreEqual( 0, p.emptyFloat.Value );
				Assert.AreEqual( 3, p.structNone.Value );
				
				Assert.AreEqual( 6, p.emptyCoal.Value );
				Assert.AreEqual( 5, p.structCoal.Value );
			}
		}
		
		[Test]
		public void NullNoJS()
		{
			var p = new UX.Expression.NullNoJS();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( 9, p.ta.Value );
				Assert.AreEqual( 9, p.tb.Value );
				Assert.AreEqual( 2, p.tc.Value );
				Assert.AreEqual( 8, p.td.Value );
				Assert.AreEqual( false, p.hc.ObjectValue );
				Assert.AreEqual( true, p.nc.ObjectValue );
				Assert.AreEqual( true, p.nd.ObjectValue );
				
				p.a.Value = 12;
				p.c.Value = p.b.Value;
				root.PumpDeferred();
				Assert.AreEqual( 12, p.ta.Value );
				Assert.AreEqual( 9, p.tb.Value );
				Assert.AreEqual( 3, p.td.Value );
				Assert.AreEqual( true, p.hc.ObjectValue );
				Assert.AreEqual( false, p.nc.ObjectValue );
				Assert.AreEqual( false, p.nd.ObjectValue );
			}
		}
		
		[Test]
		public void IsDefined()
		{
			var p  = new UX.Expression.IsDefined();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( true, p.ha.BoolValue ); //it's null, but there
				Assert.AreEqual( false, p.hb.BoolValue );
				
				root.StepFrameJS();
				Assert.AreEqual( false, p.hc.BoolValue );
				Assert.AreEqual( true, p.hd.BoolValue );
				
				p.callFlip.Perform();
				root.StepFrameJS();
				Assert.AreEqual( true, p.hc.BoolValue );
				Assert.AreEqual( false, p.hd.BoolValue );
			}
		}
	}
}
