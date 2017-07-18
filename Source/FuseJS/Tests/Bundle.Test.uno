using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Collections;
using Uno.Testing;
using Uno.Threading;
using Uno.Text;
using FuseTest;
using Uno.Compiler.ExportTargetInterop;

namespace FuseJS.Test
{
	
	public class BundleTests : TestBase
	{
		const int JS_FRAMES_TO_STEP = 5;
		[Test]
		public void TestList()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleList();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			e.CallTest.Perform();
			root.MultiStepFrameJS(JS_FRAMES_TO_STEP);
			Assert.AreEqual("True", e.output.Value);
		}

		[Test]
		public void TestRead()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleRead();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			e.CallTest.Perform();
			root.MultiStepFrameJS(JS_FRAMES_TO_STEP);
			Assert.AreEqual("True", e.output.Value);
		}

		[Test]
		public void TestReadSync()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleReadSync();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			e.CallTest.Perform();
			root.MultiStepFrameJS(JS_FRAMES_TO_STEP);
			Assert.AreEqual("True", e.output.Value);
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-public/issues/117")]
		public void TestExtract()
		{
			new FuseJS.Bundle();
			new Fuse.FileSystem.FileSystemModule();
			var e = new UX.BundleExtract();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			e.CallTest.Perform();
			root.MultiStepFrameJS(JS_FRAMES_TO_STEP);
			Assert.AreEqual("True", e.output.Value);
		}

		[Test]
		public void TestReadBuffer()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleReadBuffer();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			e.CallTest.Perform();
			root.MultiStepFrameJS(JS_FRAMES_TO_STEP);
			Assert.AreEqual("True", e.output.Value);
		}
	}
}
