using Uno;
using Uno.Testing;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	public class ShapeTest : TestBase
	{
		[Test]
		public void NullFill()
		{
			var s = new Rectangle();
			s.Fill = null;

			Assert.AreEqual(0, s.Fills.Count);
		}

		[Test]
		public void NullStoke()
		{
			var s = new Rectangle();
			s.Stroke = null;

			Assert.AreEqual(0, s.Strokes.Count);
		}

		[Test]
		public void LoadingResource()
		{
			var p = new UX.Shape.LoadingResource();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, TriggerProgress(p.WL));
				Assert.AreEqual(1, TriggerProgress(p.WB));
				
				p.LB.IsLoading = false;
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.WL));
				Assert.AreEqual(0, TriggerProgress(p.WB));
			}
		}
		
		[Test]
		/* Assuming LoadingResource is working this is the quickest way to test that ImageFill 
			reports loading as well */
		public void LoadingImageFill()
		{
			var p = new UX.Shape.LoadingImageFill();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//the image source starts pending, which also triggers the IsLoading (should it?)
				Assert.AreEqual(1, TriggerProgress(p.WL));
				Assert.AreEqual(1, TriggerProgress(p.WB));
				
				p.LI.MarkLoading();
				root.PumpDeferred();
				Assert.AreEqual(1, TriggerProgress(p.WL));
				Assert.AreEqual(1, TriggerProgress(p.WB));
				
				p.LI.MarkReady();
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.WL));
				Assert.AreEqual(0, TriggerProgress(p.WB));
			}
		}
	}
	
}
