using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.Test
{
	public class NodeGroupTest : TestBase
	{
		[Test]
		//a variant of the 1063 issue without using a trigger
		public void Variant1063()
		{
			var p = new UX.NodeGroup.Variant1063();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.innerPanel.IsActive = false;
				Assert.IsTrue(p.B.Children.Contains(p.C));
				root.StepFrame(1.1f);
				Assert.IsFalse(p.B.Children.Contains(p.C));

				//reenabled while deleting.
				p.innerPanel.IsActive = true;
				Assert.IsTrue(p.B.Children.Contains(p.C));
				p.innerPanel.IsActive = false;
				p.innerPanel.IsActive = true;
				Assert.IsTrue(p.B.Children.Contains(p.C));
				
				//remove outer while removing
				p.innerPanel.IsActive = false;
				p.outerPanel.IsActive = false;
				root.PumpDeferred();
				Assert.IsFalse(p.A.Children.Contains(p.B));
				Assert.IsFalse(p.B.Children.Contains(p.C));
				
				p.outerPanel.IsActive = true;
				Assert.IsTrue(p.A.Children.Contains(p.B));
				Assert.IsFalse(p.B.Children.Contains(p.C));
				
				//remove inner while outer not visible
				p.innerPanel.IsActive = true;
				Assert.IsTrue(p.B.Children.Contains(p.C));
				
				p.outerPanel.IsActive = false;
				root.PumpDeferred();
				Assert.IsFalse(p.A.Children.Contains(p.B));
				
				p.innerPanel.IsActive = false;
				root.PumpDeferred();
				Assert.IsFalse(p.B.Children.Contains(p.C));
			}
		}
		
		[Test]
		//a simple practical test
		public void GridLine()
		{
			var p = new UX.NodeGroup.GridLine();
			using (var root = TestRootPanel.CreateWithChild(p,int2(300)))
			{
				//evidence of being included correctly
				Assert.AreEqual(float2(0), p.A.C1.ActualPosition);
				Assert.AreEqual(float2(100), p.B.C2.ActualPosition);
				Assert.AreEqual(float2(200), p.C.C3.ActualPosition);
			}
		}
		
		[Test]
		public void Resources()
		{
			var p = new UX.NodeGroup.Resources();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float4(0.5f,1,0.5f,1), p.T.TextColor );
				Assert.AreEqual( "😀", p.T.Value );
			}
		}
	}
}
