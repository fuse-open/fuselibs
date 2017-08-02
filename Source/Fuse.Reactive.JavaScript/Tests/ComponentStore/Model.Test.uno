using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ModelTest : TestBase
	{
		[Test]
		public void Test1()
		{
            var e = new UX.Model.Basic();
            using (var root = TestRootPanel.CreateWithChild(e))
            {
                root.StepFrameJS();
//                 Assert.AreEqual(false, e.mySwitch.Value);
//                 Assert.AreEqual(true, e.myFlippedSwitch.Value);
// 
//                 e.mySwitch.Value = true;
// 
//                 Assert.AreEqual(true, e.mySwitch.Value);
//                 root.StepFrameJS();
//                 Assert.AreEqual(true, e.mySwitch.Value);
//                 Assert.AreEqual(false, e.myFlippedSwitch.Value);
// 
//                 e.myFlippedSwitch.Value = true;
//                 Assert.AreEqual(true, e.myFlippedSwitch.Value);
//                 root.StepFrameJS();
// 
//                 Assert.AreEqual(false, e.mySwitch.Value);
//                 Assert.AreEqual(true, e.myFlippedSwitch.Value);
// 
//                 e.myFlippedSwitch.Value = false;
//                 e.mySwitch.Value = true;
//                 e.myFlippedSwitch.Value = true;
//                 root.StepFrameJS();
// 
//                 Assert.AreEqual(false, e.mySwitch.Value);
//                 Assert.AreEqual(true, e.myFlippedSwitch.Value);

            }
        }
    }
}