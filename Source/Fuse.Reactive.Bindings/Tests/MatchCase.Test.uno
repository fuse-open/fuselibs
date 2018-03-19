using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class MatchCaseTest : TestBase
	{
		[Test]
		public void Issue2397()
		{
			var e = new UX.Issue2397();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(2, e.Container.VisualChildCount);
				Assert.AreEqual("OneTwo", GetText(e.Container));
			}
		}
		
		[Test]
		/* Ensures items are added in the correct order */
		public void MatchOrder()
		{
			var e = new UX.MatchOrder();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "123", GetText(e.A) );
			}
		}
		
		string GetText(Visual root)
		{
			var q = "";
			for (int i=0; i < root.Children.Count; ++i)
			{
				var t = root.Children[i] as Text;
				if (t != null)
					q += t.Value;
			}
			return q;
		}
		
		[Test]
		/** More ordering, ensuring multiple matches also in order */
		public void MatchOrder2()
		{
			var e = new UX.MatchOrder2();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "01234", GetText(e.A) );

				e.CallFlip.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "*1!4", GetText(e.A) );

				e.CallFlip.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "01234", GetText(e.A) );
			}
		}
		
		[Test]
		/** https://github.com/fusetools/fuselibs-private/issues/2802 */
		public void MatchEachOrder()
		{
			var e = new UX.MatchEachOrder();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "123", GetText(e) );
			}
		}
		
		[Test]
		/** When the child inserts nodes, variation of 2802 */
		public void MatchMultipleOrder()
		{
			var e = new UX.MatchMultipleOrder();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "112233", GetText(e) );
			}
		}
	}
}
