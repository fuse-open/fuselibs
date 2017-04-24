using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Drawing.Test
{
	public class BrushTest : TestBase
	{
		[Test]
		public void Binding()
		{
			TestRootPanel.RequireModule<Fuse.Drawing.BrushConverter>();
			var p = new UX.Brush.Binding();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( float4(1,0.5f,0,1), (p.A.Fill as SolidColor).Color );
				Assert.AreEqual( float4(8/15f,1,8/15f,1), (p.B.Fill as SolidColor).Color );
			}
		}
	}
}