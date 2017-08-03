using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ModelTest : TestBase
	{
		[Test]
		public void Basic()
		{
            var e = new UX.Model.Basic();
            using (var root = TestRootPanel.CreateWithChild(e))
            {
                root.StepFrameJS();
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
        
        [Test]
        public void List()
        {
			var e = new UX.Model.List();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "", e.oc.JoinValues() );
				
				e.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "5", e.oc.JoinValues() );
			}
        }
        
        [Test]
        [Ignore("Not parsing correctly, see UX file")]
        public void PathName()
        {
			var e = new UX.Model.PathName();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				//Assert.AreEqual("abc", e.v.Value);
			}
        }
        
        [Test]
        public void Nested()
        {
			var e = new UX.Model.Nested();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("2,2,1", GetDudZ(e));
				
				e.callModB.Perform();
				root.StepFrameJS();
				Assert.AreEqual("3,3,1", GetDudZ(e));
				
				e.callRepC.Perform();
				root.StepFrameJS();
				Assert.AreEqual("3,1,1", GetDudZ(e));
			}
        }
        
        [Test]
        public void Function()
        {
			var e = new UX.Model.Function();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("***", e.s.UseValue);
				
				e.callIncr.Perform();
				root.StepFrameJS();
				root.StepFrameJS();
				Assert.AreEqual("****", e.s.UseValue);
			}
        }
    }
}