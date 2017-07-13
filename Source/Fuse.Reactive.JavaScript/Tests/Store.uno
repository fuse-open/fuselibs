using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class StoreTest : TestBase
	{
		[Test]
		public void Basics()
		{
			var e = new UX.Store();
			var root = TestRootPanel.CreateWithChild(e);

			root.StepFrameJS();
			AssertList(e, "orange", "lemon", "banana", "coconut");
			Assert.AreEqual(e.s.Value, "lemon");

			e.change1.Perform();
			root.StepFrameJS();
			AssertList(e, "orange", "lemon", "banana", "coconut", "grape");
			Assert.AreEqual(e.s.Value, "lemon");

			e.change2.Perform();
			root.StepFrameJS();
			AssertList(e, "orange", "lemon", "lemon", "banana", "coconut", "grape");
			Assert.AreEqual(e.s.Value, "lemon");

			e.change3.Perform();
			root.StepFrameJS();
			AssertList(e, "orange", "lemon", "coconut", "grape");
			Assert.AreEqual(e.s.Value, "lemon");

			e.change4.Perform();
			root.StepFrameJS();
			AssertList(e, "orange", "fish", "coconut", "grape");
			Assert.AreEqual(e.s.Value, "fish");

			Assert.AreEqual(e.bar.Value, "3");
			e.change5.Perform();
			root.StepFrameJS();
			Assert.AreEqual(e.bar.Value, "1");

			e.change6.Perform();
			root.StepFrameJS();
			Assert.AreEqual(e.bar.Value, "8");
			AssertList(e, "batman", "batman", "batman");
			Assert.AreEqual(e.s.Value, "batman");

			// Verify that dependent module was re-evaluated
			e.change7.Perform();
			root.StepFrameJS();
		}

		void AssertList(UX.Store e, params string[] p)
		{
			for (int i = 0; i < p.Length; i++)
				Assert.AreEqual(p[i], ((Text)e.p.Children[i+1]).Value);
		}
	}
}