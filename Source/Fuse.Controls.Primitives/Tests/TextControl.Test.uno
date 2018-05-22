using Uno;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Controls.Primitives.Test
{
	class MockTextControl : TextControl
	{
	}

	public class TextControlTest : TestBase
	{
		[Test]
		public void MaxValueCrashBug()
		{
			var tc = new MockTextControl();
			tc.MaxLength = 2;
			tc.Value = null;

			Assert.AreEqual("", tc.Value);
		}
		
		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void TextInputBinding()
		{
			var p = new UX.TextInput.Binding();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("one", p.T1.Value);
				Assert.AreEqual("one", p.T2.Value);
				
				p.T1.Value = "two";
				root.StepFrameJS();
				Assert.AreEqual("two", p.T1.Value);
				Assert.AreEqual("two", p.T2.Value);
			}
		}
	}
}
