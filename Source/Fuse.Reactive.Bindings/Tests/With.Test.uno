using Uno;
using Uno.Testing;

using Fuse;

using FuseTest;

namespace Fuse.Test
{
	public class WithTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.With.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "Un,Deux", GetText(p));
			}
		}
		
		[Test]
		public void Observable()
		{
			var p = new UX.With.Observable();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("Un,Deux", GetText(p));
				
				p.callNext.Perform();
				root.StepFrameJS();
				Assert.AreEqual("i,ii", GetText(p));
			}
		}
		
		[Test]
		public void Order()
		{
			var p = new UX.With.Order();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("A,B", GetText(p));
			}
		}
		
		[Test]
		//https://github.com/fusetools/fuselibs-public/issues/803
		public void EachOrder()
		{
			var p = new UX.With.EachOrder();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("1,2,3,4", GetText(p));
				Assert.AreEqual("1,-1,2,-2,3,-3,4,-4", GetText(p.s));
			}
		}
	}
}
