using Uno;

using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class BringToFrontTest : TestBase
	{
		[Test]
		public void ToFront()
		{
			var p = new UX.BringToFront.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "C,B,A", GetDudZ(p));
				
				p.bFront.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( "C,A,B", GetDudZ(p));
				
				p.cFront.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( "A,B,C", GetDudZ(p));
			}
		}
		
		[Test]
		public void ToBack()
		{
			var p = new UX.BringToFront.BackBasic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "C,B,A", GetDudZ(p));
				
				p.bBack.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( "B,C,A", GetDudZ(p));
				
				p.aBack.Pulse();
				root.PumpDeferred();
				Assert.AreEqual( "A,B,C", GetDudZ(p));
			}
		}
	}
}
