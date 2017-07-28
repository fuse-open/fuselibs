using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ComponentStoreTests : TestBase
	{
		[Test]
		public void Test1()
		{
            var e = new UX.ComponentStore.Test1();
            using (var root = TestRootPanel.CreateWithChild(e))
            {
                Assert.AreEqual(false, e.mySwitch.Value);
                Assert.AreEqual(true, e.myFlippedSwitch.Value);

                e.mySwitch.Value = true;

                Assert.AreEqual(true, e.mySwitch.Value);
                root.StepFrameJS();
                Assert.AreEqual(true, e.mySwitch.Value);
                Assert.AreEqual(false, e.myFlippedSwitch.Value);

                e.myFlippedSwitch.Value = true;
                Assert.AreEqual(true, e.myFlippedSwitch.Value);
                root.StepFrameJS();

                Assert.AreEqual(false, e.mySwitch.Value);
                Assert.AreEqual(true, e.myFlippedSwitch.Value);

                e.myFlippedSwitch.Value = false;
                e.mySwitch.Value = true;
                e.myFlippedSwitch.Value = true;
                root.StepFrameJS();

                Assert.AreEqual(false, e.mySwitch.Value);
                Assert.AreEqual(true, e.myFlippedSwitch.Value);

            }
        }
    }
}