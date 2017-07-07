using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Testing;

using Fuse.Controls.Test.Helpers;
using Fuse.Elements;
using Fuse.Layouts;
using Fuse.Resources;
using FuseTest;

using FuseTest;

namespace Fuse.Controls.Test
{
    public class RootedCounter: Node
    {
        public static int Count = 0;

        protected override void OnRooted()
        {
            Count++;
        }

        protected override void OnUnrooted()
        {
            Count--;
        }
    }

    public class AssetTest : TestBase
	{
		[Test]
		public void AssetBasics()
		{
            var c = new UX.AssetTest();
			var root = TestRootPanel.CreateWithChild(c);

            Assert.AreEqual(28, RootedCounter.Count);
            c.icon7.Number = 13;
			root.StepFrame();
            Assert.AreEqual(28+13, RootedCounter.Count);
            c.icon7.Number = 5;
			root.StepFrame();
            Assert.AreEqual(28, RootedCounter.Count);
            c.icon4.Number = 13;
			root.StepFrame();
            Assert.AreEqual(28+13, RootedCounter.Count);
            c.icon9.Number = 13;
			root.StepFrame();
            Assert.AreEqual(28+13+13-6, RootedCounter.Count);

			root.Children.Remove(c);
			root.StepFrame();
			Assert.AreEqual(0, RootedCounter.Count);

			Assert.AreEqual(0, Asset._rootedAssets.Count);
        }
    }
}