using Uno;
using Uno.Testing;

using FuseTest;

namespace Fuse.Triggers.Test
{
	public class WhileStringUnitTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.WhileStringBasic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				//sanity test, unsure if we guarantee this setup (No Compare)
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.Value = "Something";
				p.WS.Compare = "Something";
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.Value = "Other";
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));

				p.WS.Test = WhileStringTest.IsNotEmpty;
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.Value = "";
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));

				p.WS.Test = WhileStringTest.IsEmpty;
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.Value = "hello";
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));
			}
		}
		
		[Test]
		public void CaseSensitive()
		{
			var p = new UX.WhileStringCase();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.CaseSensitive = true;
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));
			}
		}
		
		[Test]
		public void Contains()
		{
			var p = new UX.WhileStringContains();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.WS));

				p.WS.Value="stoney";
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));
			}
		}
		
		[Test]
		public void Length()
		{
			var p = new UX.WhileStringLength();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, TriggerProgress(p.WS));

				p.WS.Value = "abc";
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.MinLength = 4;
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));

				p.WS.Value = "abcdefghij";
				root.IncrementFrame();
				Assert.AreEqual(1, TriggerProgress(p.WS));

				p.WS.MaxLength = 9;
				root.IncrementFrame();
				Assert.AreEqual(0, TriggerProgress(p.WS));
			}
		}
	}
}
