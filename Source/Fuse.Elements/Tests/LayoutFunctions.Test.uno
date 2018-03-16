using Uno;
using Uno.Compiler;
using Uno.Testing;

using FuseTest;

namespace Fuse.Elements.Test
{
	public class LayoutFunctionsTest : TestBase
	{
		[Test]
		//https://github.com/fusetools/fuselibs-private/issues/4189
		public void Issue4189()
		{
			var p = new global::UX.LayoutFunctions.Issue4189();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrame();
				var b = p.FindNodeByName("b") as Element;
				Assert.AreEqual(float2(10,20), b.ActualPosition);
				Assert.AreEqual(float2(300,400), b.ActualSize);
				
				Assert.AreEqual(float2(10,20), p.c.ActualPosition);
				Assert.AreEqual(float2(300,400), p.c.ActualSize);
				
				var d = p.FindNodeByName("d") as Element;
				Assert.AreEqual(float2(10,20), b.ActualPosition);
				Assert.AreEqual(float2(300,400), b.ActualSize);
			}
		}
		
		[Test]
		public void LostData()
		{
			var p = new global::UX.LayoutFunctions.LostData();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				for (int i=0; i<3; ++i)
				{
					Assert.AreEqual( -1, p.dw.Value );
					Assert.AreEqual( -1, p.dh.Value );
					
					p.wt.Value = true;
					root.StepFrame();
					Assert.AreEqual( 10, p.dw.Value );
					Assert.AreEqual( 20, p.dh.Value );
					
					p.wt.Value = false;
					root.StepFrame();
				}
			}
		}
		
		[Test]
		public void Alternates()
		{
			var p = new global::UX.LayoutFunctions.Alternates();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(2,p.xa.Value);
				Assert.AreEqual(3,p.xb.Value);
				Assert.AreEqual(4,p.yb.Value);
				Assert.AreEqual(6,p.yc.Value);
			}
		}
	}
}
