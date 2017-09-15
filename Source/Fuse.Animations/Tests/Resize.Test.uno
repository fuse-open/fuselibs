using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Animations.Test
{
	public class ResizeTest : TestBase
	{
		[Test]
		public void ResizeRelative()
		{
			var p = new UX.ResizeRelative();
			using (var root = TestRootPanel.CreateWithChild(p, int2(500,1000)))
			{
				Assert.AreEqual(float2(100,80),p.B.ActualSize);

				p.A.Width = 150;
				p.A.Height = 200;
				root.IncrementFrame();
				Assert.AreEqual(float2(150,200),p.B.ActualSize);
				Assert.AreEqual(float2(200,300),p.B.IntendedSize);

				p.B.Width = 300;
				p.B.Height = 500;
				root.IncrementFrame();
				Assert.AreEqual(float2(150,200),p.B.ActualSize);
				Assert.AreEqual(float2(300,500),p.B.IntendedSize);

				p.W.Value = false;
				root.IncrementFrame();
				Assert.AreEqual(float2(300,500),p.B.ActualSize);
				Assert.AreEqual(float2(300,500),p.B.IntendedSize);
			}
		}
	}
}
