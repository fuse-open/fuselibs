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
		[Ignore("https://github.com/fusetools/fuselibs/issues/3806")]
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
	}
}
