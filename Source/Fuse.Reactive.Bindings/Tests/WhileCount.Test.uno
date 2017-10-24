using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Scripting;
using Fuse.Scripting.JavaScript;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class WhileCountTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var e = new UX.WhileCount.Basic();
			Observable items = null;
			using (var root = TestRootPanel.CreateWithChild(e))
			{	
				//0
				root.StepFrameJS();
				Assert.AreEqual("ADEH", GetText(e.T));
				
				//test indication that all items are the same object (and the subscriptions are correct)
				items = e.W1.Items as Observable;
				Assert.AreEqual(items, e.W2.Items);
				Assert.AreEqual(8,items.TestObserverCount);
				
				//1
				e.Add.Perform();
				root.StepFrameJS();
				Assert.AreEqual("CDE", GetText(e.T));
				
				//2
				e.Add.Perform();
				root.StepFrameJS();
				Assert.AreEqual("BCEG", GetText(e.T));
				
				//3
				e.Add.Perform();
				root.StepFrameJS();
				Assert.AreEqual("BCH", GetText(e.T));
				
				//2
				e.Remove.Perform();
				root.StepFrameJS();
				Assert.AreEqual("BCEG", GetText(e.T));
				
				//1
				e.Set.Perform();
				root.StepFrameJS();
				Assert.AreEqual("CDE", GetText(e.T));
				
				//0
				e.Clear.Perform();
				root.StepFrameJS();
				Assert.AreEqual("ADEH", GetText(e.T));
			}
			
			//test cleanup of subscriptions
			var c = 0;
			for (int i=0; i < e.T.Children.Count; ++i)
			{
				var wc = e.T.Children[i] as WhileCount;
				if (wc != null)
				{
					c++;
					Assert.IsTrue(wc.TestIsClean);
				}
			}
			Assert.AreEqual(8,c);

			Assert.AreEqual(0,items.TestObserverCount);
		}
		
		string GetText(Visual n)
		{
			string a = "";
			for (int i=0; i < n.Children.Count; ++i)
			{
				var t = n.Children[i] as Text;
				if (t != null)
					a += t.Value;
			}
			return a;
		}
	}
}