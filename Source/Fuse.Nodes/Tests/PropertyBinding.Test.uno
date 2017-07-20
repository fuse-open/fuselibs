using Fuse;
using FuseTest;
using Uno;
using Uno.Testing;

namespace Fuse.Test
{
	public class PropertyBindingTest : TestBase
	{
		[Test]
		public void CompatibilityTest()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var t = new UX.PropertyBindingTest();
				using (var root = TestRootPanel.CreateWithChild(t))
					root.IncrementFrame();

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(6, diagnostics.Count);

				Assert.AreEqual("Cannot convert '0' to target type 'Fuse.Drawing.Stroke'", diagnostics[0].Message);
				Assert.AreEqual("Cannot convert '0, 0, 0, 0' to target type 'Fuse.Drawing.Stroke'", diagnostics[1].Message);
				Assert.AreEqual("Cannot convert '0' to target type 'Fuse.Drawing.Stroke'", diagnostics[2].Message);
				Assert.AreEqual("Cannot convert '0, 0, 0, 0' to target type 'Fuse.Drawing.Stroke'", diagnostics[3].Message);
				Assert.AreEqual("Cannot convert '0' to target type 'Fuse.Drawing.Stroke'", diagnostics[4].Message);
				Assert.AreEqual("Cannot convert '0, 0, 0, 0' to target type 'Fuse.Drawing.Stroke'", diagnostics[5].Message);
			}
		}
	}
	
}
