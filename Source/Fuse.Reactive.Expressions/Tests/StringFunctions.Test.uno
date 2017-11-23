using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Expressions.Test
{
	public class StringFunctionsTest : TestBase
	{
		[Test]
		public void ToUpper()
		{
			var p = new UX.StringFunctions.ToUpper();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(null, p.NullInput.String);
				Assert.AreEqual(null, p.NullResult.String);
			}
		}

		[Test]
		public void ToLower()
		{
			var p = new UX.StringFunctions.ToLower();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(null, p.NullInput.String);
				Assert.AreEqual(null, p.NullResult.String);
			}
		}
	}
}
