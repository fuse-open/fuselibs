using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class CycleTest : TestBase
	{
		[Test]
		public void Square()
		{
			var p = new UX.CycleSquare();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0,p.P1.X.Value);
				root.StepFrame(0.25f);
				Assert.AreEqual(0,p.P1.X.Value);
				root.StepFrame(0.25f);
				Assert.AreEqual(100,p.P1.X.Value);
				root.StepFrame(0.25f);
				Assert.AreEqual(100,p.P1.X.Value);
				root.StepFrame(0.25f);
				Assert.AreEqual(0,p.P1.X.Value);
			}
		}
		
		[Test]
		public void SawtoothBaseOffset()
		{
			var p = new UX.CycleSawtooth();
			using (var root = TestRootPanel.CreateWithChild(p, TestRootPanel.CreateFlags.NoIncrement))
			{
				//first frame will make one step
				Assert.AreEqual( float2(50,25), p.T1.XY );

				var tol = root.StepIncrement; //roughly okay
				root.StepFrame(0.5f);
				Assert.AreEqual( float2(150,75), p.T1.XY, tol );

				root.StepFrame(0.25f);
				Assert.AreEqual( float2(200,100), p.T1.XY, tol );

				//it's hard to check exactly the changeover, so we just go a bit over
				root.StepFrame(0.26f);
				Assert.AreEqual( float2(52,26), p.T1.XY, tol );
			}
		}
	}
}
