using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
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
	}
}
