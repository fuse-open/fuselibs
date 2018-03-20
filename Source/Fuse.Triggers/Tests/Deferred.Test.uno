using Uno;
using Uno.Testing;
using Uno.UX;

using Fuse.Controls;

using FuseTest;

namespace Fuse.Test
{
	public class DeferredTest : TestBase
	{
		[Test]
		public void Basic()
		{
			//to allow only one node per frame
			var prevTestTimeLimit = DeferredManager.TestTimeLimit;
			DeferredManager.TestTimeLimit = 0;

			try
			{
				var p = new UX.DeferredBasic();
				using (var root = TestRootPanel.CreateWithChild(p))
				{
					Assert.AreEqual("", GetText(p));

					root.StepFrame();
					Assert.AreEqual("1", GetText(p));

					root.StepFrame();
					Assert.AreEqual("12", GetText(p));

					root.StepFrame();
					Assert.AreEqual("123", GetText(p));
				}
			}
			finally
			{
				DeferredManager.TestTimeLimit = prevTestTimeLimit;
			}
		}
		
		[Test]
		public void Busy()
		{
			var p = new UX.DeferredBusy();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "Busy", GetText(p));
				root.StepFrame();
				Assert.AreEqual("1", GetText(p));
			}
		}
		
		string GetText(Visual root)
		{
			string t = "";
			for (int i=0; i < root.Children.Count; ++i)
			{
				var tx = root.Children[i] as Text;
				if (tx != null)
					t += tx.Value;
			}
			return t;
		}
		
		[Test]
		//https://github.com/fusetools/fuselibs-private/issues/2806
		public void Unroot()
		{
			var p = new UX.DeferredUnroot();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameDeferred();
				Assert.AreEqual(6, p.Children.Count);
			}
		}
		
		[Test]
		public void Each()
		{
			var p = new UX.DeferredEach();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				root.StepFrameDeferred();
				Assert.AreEqual( "01", GetText(p));

				p.CallAdd.Perform();
				root.StepFrameJS();
				root.StepFrameDeferred();
				Assert.AreEqual( "012", GetText(p));

				p.CallAdd.Perform();
				root.StepFrameJS();
				root.StepFrameDeferred();
				Assert.AreEqual( "0123", GetText(p));

				p.CallRemove1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "023", GetText(p));

				p.CallAdd2.Perform();
				root.StepFrameJS();
				root.StepFrameDeferred();
				Assert.AreEqual( "0243", GetText(p));
			}
		}
		
		[Test]
		public void Match()
		{
			var p = new UX.DeferredMatch();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameDeferred();
				Assert.AreEqual( "123", GetText(p) );
			}
		}
	}
}
