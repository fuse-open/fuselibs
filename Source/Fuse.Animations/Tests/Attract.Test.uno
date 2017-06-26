using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class AttractTest: TestBase
	{
		[Test]
		public void Basic()
		{	
			var p =  new UX.Attract.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(50, p.T.X);
				
				p.slider.Value = 100;
				root.StepFrame(1f);
				Assert.AreEqual(75, p.T.X);
				
				root.StepFrame(1f);
				Assert.AreEqual(100,p.T.X);
			}
		}
	}
}