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
	public class BundleTest : TestBase
	{
		[Test]
		public void TestList()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleList();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.CallTest.Perform();

				while (string.IsNullOrEmpty(e.output.Value))
					root.StepFrameJS();

				Assert.AreEqual("True", e.output.Value);
			}
		}

		[Test]
		public void TestRead()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleRead();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.CallTest.Perform();


				while (string.IsNullOrEmpty(e.output.Value))
					root.StepFrameJS();

				Assert.AreEqual("True", e.output.Value);
			}
		}

		[Test]
		public void TestReadSync()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleReadSync();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.CallTest.Perform();

				while (string.IsNullOrEmpty(e.output.Value))
					root.StepFrameJS();

				Assert.AreEqual("True", e.output.Value);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/117")]
		public void TestExtract()
		{
			new FuseJS.Bundle();
			new Fuse.FileSystem.FileSystemModule();
			var e = new UX.BundleExtract();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.CallTest.Perform();

				while (string.IsNullOrEmpty(e.output.Value))
					root.StepFrameJS();

				Assert.AreEqual("True", e.output.Value);
			}
		}

		[Test]
		public void TestReadBuffer()
		{
			new FuseJS.Bundle();
			var e = new UX.BundleReadBuffer();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.CallTest.Perform();

				while (string.IsNullOrEmpty(e.output.Value))
					root.StepFrameJS();

				Assert.AreEqual("True", e.output.Value);
			}
		}
	}
}
