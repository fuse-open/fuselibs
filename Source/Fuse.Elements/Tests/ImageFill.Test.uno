using Uno;
using Uno.Testing;

using FuseTest;

using Fuse.Drawing;
using Fuse.Resources;

namespace Fuse.Elements.Test
{
	public class ImageFillTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var imageFill = new ImageFill();

			Assert.AreEqual(WrapMode.Repeat, imageFill.WrapMode);
		}
		
		[Test]
		public void ResourceBasic()
		{
			var p = new global::UX.ImageFill.Resource();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				WaitLoad(root, p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0,1,0,1), int2(50));
				}
				
				root.Children.Remove(p);
				root.StepFrame(61); //UnloadUnused waits 60s
				Assert.AreEqual(0,DisposalManager.TestMemoryResourceCount);
				Assert.IsTrue(FramebufferPool.TestIsLockedClean);
				Assert.IsTrue(p.IF.TestIsClean);
			}
		}
		
		[Test]
		//tests a variation that changes the resource, this caused the leak in 
		//https://github.com/fusetools/fuselibs-private/issues/3502
		public void ResourceReplace()
		{
			var p = new global::UX.ImageFill.ResourceReplace();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				root.StepFrameJS();
				WaitLoad(root, p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0,1,0,1), int2(50));
				}
				
				p.Next.Perform();
				root.StepFrameJS();
				WaitLoad(root, p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(1,0,0,1), int2(50));
				}
				
				root.Children.Remove(p);
				root.StepFrame(61); //UnloadUnused waits 60s
				Assert.AreEqual(0,DisposalManager.TestMemoryResourceCount);
				Assert.IsTrue(FramebufferPool.TestIsLockedClean);
				Assert.IsTrue(p.IF.TestIsClean);
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/uno/issues/934")]
		public void UrlResource()
		{
			var p = new global::UX.ImageFill.UrlResource();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				WaitLoad(root, p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0,1,0,1), int2(50));
				}
				
				Assert.AreEqual(1,DisposalManager.TestMemoryResourceCount);
				root.Children.Remove(p);
				root.StepFrame(61); //UnloadUnused waits 60s
				Assert.AreEqual(0,DisposalManager.TestMemoryResourceCount);
				Assert.IsTrue(FramebufferPool.TestIsLockedClean);
				Assert.IsTrue(p.IF.TestIsClean);
			}
		}
		
		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-private/issues/3511")]
		public void Calibrate()
		{
			var p = new global::UX.ImageFill.Calibrate();
			using (var root = TestRootPanel.CreateWithChild(p,int2(31)))
			{
				WaitLoad(root,p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(1,0,0,1), int2(2));
					fb.AssertPixel(float4(0,0,0,1), int2(6));


					fb.AssertPixel(float4(1,0,0,1), int2(11));
					fb.AssertPixel(float4(0,0,0,1), int2(15));
				}

				p.IF.Source = p.C50;
				WaitLoad(root,p.W);
				using (var fb = root.CaptureDraw())
				{
					//TODO: this is blurry here, thus the check fails, seet he IGNORE
					fb.AssertPixel(float4(0,0,0,1), int2(15));
				}
			}
		}
		
		[Test]
		//going to background releases temp resources (image is also marked to release here to simplify the test)
		public void Dispose()
		{
			var p = new global::UX.ImageFill.Dispose();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				WaitLoad(root,p.W);
				using (var fb = root.CaptureDraw())
				{
					fb.AssertPixel(float4(0,1,0,1), int2(10));
				}
				
				DisposalManager.Clean(DisposalRequest.Background);
				Assert.IsTrue(p.IF.TestIsClean);
			}
		}
		
		[Test]
		//Loading is immediately set, not waiting until first draw
		//https://github.com/fusetools/fuselibs-private/issues/3514
		public void Loading()
		{
			var p = new global::UX.ImageFill.Loading();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1,p.C.PerformedCount);
				//if the loading hasn't started this will wait forever
				WaitLoad(root, p.W);
				Assert.AreEqual(1,p.C.PerformedCount);
			}
		}
		
		void WaitLoad(TestRootPanel root, Fuse.Triggers.Trigger t)
		{
			while( TriggerProgress(t) > 0 || t.PlayState != Fuse.Triggers.TriggerPlayState.Stopped) {
				root.StepFrame();
			}
		}
	}
}
