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
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(null, p.NullInput.String);
				Assert.AreEqual(null, p.NullResult.String);

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.Contains("Failed to compute value", diagnostics[0].Message);
				Assert.Contains("Failed to compute value", diagnostics[1].Message);
			}
		}

		[Test]
		public void ToLower()
		{
			var p = new UX.StringFunctions.ToLower();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(null, p.NullInput.String);
				Assert.AreEqual(null, p.NullResult.String);

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(2, diagnostics.Count);
				Assert.Contains("Failed to compute value", diagnostics[0].Message);
				Assert.Contains("Failed to compute value", diagnostics[1].Message);
			}
		}
	}
}
