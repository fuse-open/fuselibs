using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class ElementTest : TestBase
	{
		[Test]
		public void PositionSize()
		{
			var p = new global::UX.Element.PositionSize();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( new Size(20, Unit.Unspecified), p.a.X );
				Assert.AreEqual( new Size(30, Unit.Percent), p.a.Y );
				Assert.AreEqual( new Size(40, Unit.Points), p.a.Width );
				Assert.AreEqual( new Size(50, Unit.Pixels), p.a.Height );
				
				Assert.AreEqual( new Size2( new Size(2, Unit.Pixels), new Size(3, Unit.Unspecified)), p.b.Position );
				Assert.AreEqual( new Size2( new Size(4, Unit.Percent), new Size(5, Unit.Points)), p.b.Size );
			}
		}	
	}
}
