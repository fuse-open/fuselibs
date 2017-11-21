using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;
using Fuse.Resources;
using Fuse.Resources.Exif;

namespace Fuse.Controls.Primitives.Test
{
	public class ImageTest : TestBase
	{
		[Test]
		public void AllElementProps()
		{
			var p = new Image();
			ElementPropertyTester.All(p);
		}

		[Test]
		public void AllElementLayoutTest()
		{
			var p = new Image();
			ElementLayoutTester.All(p);
		}

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

		static float3x3 TransformFromImageOrientationReference(ImageOrientation orientation)
		{
			var flip = Matrix.Scaling(1,1,1);
			var rotation = Matrix.RotationZ(0.0f);

			if (orientation.HasFlag(ImageOrientation.FlipVertical))
				flip = Matrix.Scaling(1,-1,1);

			if ((orientation & (int)0x03) == ImageOrientation.Rotate270)
				rotation = Matrix.RotationZ(Math.PIf / 2.0f);
			else if ((orientation & (int)0x03) == ImageOrientation.Rotate90)
				rotation = Matrix.RotationZ(-Math.PIf / 2.0f);
			else if ((orientation & (int)0x03) == ImageOrientation.Rotate180)
				rotation = Matrix.RotationZ(Math.PIf);

			var translateToCenter = Matrix.Translation(0.5f,0.5f,0.0f);
			var translateBack = Matrix.Translation(-0.5f,-0.5f,0.0f);
			var result = Matrix.Mul(translateBack, flip, rotation, translateToCenter);
			return float3x3(
				result.M11, result.M12, result.M13,
				result.M21, result.M22, result.M23,
				result.M41, result.M42, result.M44,
			);
		}

		public void TestImageOrientation(ImageOrientation orientation, [CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, [CallerMemberName] string memberName = "")
		{
			var tolerance = 1e-5f; // the reference-code uses trig, which is a bit inaccurate
			var expected = TransformFromImageOrientationReference(orientation);
			var transform = Image.TransformFromImageOrientation(orientation);
			Assert.AreEqual(expected, transform, tolerance, filePath, lineNumber, memberName);

			Assert.AreEqual(0, transform.M13);
			Assert.AreEqual(0, transform.M23);
			Assert.AreEqual(1, transform.M33);
		}

		[Test]
		public void TransformFromImageOrientation()
		{
			TestImageOrientation(ImageOrientation.Identity);
			TestImageOrientation(ImageOrientation.FlipVertical);
			TestImageOrientation(ImageOrientation.Rotate90);
			TestImageOrientation(ImageOrientation.Rotate90 | ImageOrientation.FlipVertical);
			TestImageOrientation(ImageOrientation.Rotate180);
			TestImageOrientation(ImageOrientation.Rotate180 | ImageOrientation.FlipVertical);
			TestImageOrientation(ImageOrientation.Rotate270);
			TestImageOrientation(ImageOrientation.Rotate270 | ImageOrientation.FlipVertical);
		}
		
		[Test]
		public void MultiDensityBasic()
		{
			var p = new UX.Image.MultiDensityBasic();
			//force the density match since the actual code path still involves a static reference to AppBase
			p.ms.MatchDensity = 1;
			using (var root = TestRootPanel.CreateWithChildDensity(p, int2(500), 1))
			{
				Assert.AreEqual(float2(100,100), p.img.ActualSize);
				root.Children.Remove(p);
			}
			
			p.ms.MatchDensity = 2;
			using (var root = TestRootPanel.CreateWithChildDensity(p, int2(500), 2))
			{
				Assert.AreEqual(float2(100,50), p.img.ActualSize);
				root.Children.Remove(p);
			}
			
			p.ms.MatchDensity = 4;
			using (var root = TestRootPanel.CreateWithChildDensity(p, int2(500), 4))
			{
				Assert.AreEqual(float2(50,100), p.img.ActualSize);
				root.Children.Remove(p);
			}
		}
		
	}
}
