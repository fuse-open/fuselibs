using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class StringFunctionsTest : TestBase
	{
		[Test]
		public void Simple()
		{
			var p = new UX.StringFunctions.Simple();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Input = "Test";
				Assert.AreEqual("TEST", p.ToUpper.Value);
				Assert.AreEqual("test", p.ToLower.Value);
			}
		}

		[Test]
		public void NullInput()
		{
			var p = new UX.StringFunctions.Simple();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.Input = null;
				Assert.AreEqual("", p.ToUpper.Value);
				Assert.AreEqual("", p.ToLower.Value);
			}
		}
	}
}
