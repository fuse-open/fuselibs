using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;

namespace Fuse.Controls.Primitives.Test
{
	public class ImageTest : TestBase
	{
		[Test]
		public void NullSource()
		{
			var img = new Image();
			using (var root = TestRootPanel.CreateWithChild(img))
			{
				var src = new HttpImageSource("https://upload.wikimedia.org/wikipedia/commons/3/39/Athene_noctua_(cropped).jpg");

				img.Source = src;
				Assert.AreEqual(src, img.Source);
				img.Source = null;
				Assert.AreEqual(null, img.Source);
			}
		}
		
		[Test]
		public void Fail()
		{
			var p = new UX.Image.Failed();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.W1));
				Assert.AreEqual(0, TriggerProgress(p.W2));
				
				p.L.Fail( "nope" );
				root.PumpDeferred();
				//Assert.AreEqual(1, TriggerProgress(p.W1)); //Not in current version
				Assert.AreEqual(1, TriggerProgress(p.W2));
				
				p.L.MarkReady();
				root.PumpDeferred();
				Assert.AreEqual(0, TriggerProgress(p.W1));
				Assert.AreEqual(0, TriggerProgress(p.W2));

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				Assert.Contains("nope", diagnostics[0].Message);
			}
		}

		[Test]
		public void RetryReload()
		{
			var p = new UX.Image.RetryReload();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.src.Fail( "Not there" );

				p.CallRetry.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, p.src.ReloadCount);

				p.src.MarkReady();
				p.CallRetry.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1, p.src.ReloadCount);

				p.CallReload.Perform();
				root.StepFrameJS();
				Assert.AreEqual(2, p.src.ReloadCount);

				var d = dg.DequeueAll();
			}
		}
	}
}
