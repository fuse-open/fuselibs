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
				
				e.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "5,6", e.oc.JoinValues() );
				
				e.callShift.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "6", e.oc.JoinValues() );
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
        
        [Test]
        [Ignore("Yeah, this fails hard")]
        public void Loop()
        {
			var e = new UX.Model.Loop();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "%", e.a.UseValue );
				Assert.AreEqual( "%", e.b.UseValue );
				Assert.AreEqual( "%", e.c.UseValue );
			}
        }
        
        [Test]
        public void Pod()
        {
			var e = new UX.Model.Pod();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("a", e.a.UseValue);
				Assert.AreEqual("b", e.b.UseValue);
				
				e.callStep1.Perform();
				Assert.AreEqual("c", e.a.UseValue);
				Assert.AreEqual("b", e.b.UseValue);
				
				e.callStep2.Perform();
				Assert.AreEqual("c", e.a.UseValue);
				Assert.AreEqual("d", e.b.UseValue);
				
				e.callStep2.Perform();
				Assert.AreEqual("c", e.a.UseValue);
				Assert.AreEqual("e", e.b.UseValue);
			}
        }
        
        [Test]
        public void Disconnected()
        {
			var e = new UX.Model.Disconnected();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(5,e.a.Value);
				
				e.callUpdateNext.Perform();
				e.callSwap.Perform();
				root.StepFrameJS();
				Assert.AreEqual(11,e.a.Value);
				
				e.callUpdateNext.Perform();
				e.callSwap.Perform();
				root.StepFrameJS();
				Assert.AreEqual(6,e.a.Value);
			}
        }
        
        [Test]
        public void AltEntry()
        {
			var e = new UX.Model.AltEntry();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "a", e.a.StringValue );
				
				e.callSetB.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "b", e.a.StringValue );
			}
        }
        
        [Test]
        public void Multi()
        {
			var e = new UX.Model.Multi();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( 1, e.a.Value );
				Assert.AreEqual( 2, e.b.Value );
				Assert.AreEqual( 3, e.c.Value );
			}
        }
        
        [Test]
        public void Bind()
        {
			var e = new UX.Model.Bind();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "bop", e.u.v.StringValue );
				Assert.AreEqual( 0, e.u.id.Value );
				
				e.u.Value = "loppy";
				root.StepFrameJS();
				Assert.AreEqual( "loppy", e.u.v.StringValue );
				Assert.AreEqual( 1, e.u.id.Value );
			}
        }
    }
}