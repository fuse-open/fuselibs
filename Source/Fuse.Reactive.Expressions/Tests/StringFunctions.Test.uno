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

		[Test]
		//basic test for types handled by Marshal
		public void Marshal()
		{
			var p = new UX.StringFunctions.Marshal();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "ab", p.str.Object );
				Assert.AreEqual( "a3", p.num.Object );
			}
		}

		[Test]
		public void Concat()
		{
			var p = new UX.StringFunctions.Concat();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "1-2", p.txt.Value );
				Assert.AreEqual( "23", p.obj.Object );
			}
		}
	}
}
