using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class DataBindingTest : TestBase
	{
		[Test]
		public void BehaviorDataContext()
		{
			// Tests that nodes get correct data context even if injected elsewhere in the tree
			// ref https://github.com/fusetools/fuselibs-private/issues/3211

			var e = new UX.DataBinding.BehaviorDataContext();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(e.pg.t1.Value, "bar");
			}
		}

		[Test]
		public void BindingDirections()
		{
			var e = new UX.DataBinding.BindingDirections();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual("foo", e.ta.Value);
				Assert.AreEqual("bar", e.tb.Value);
				Assert.AreEqual("", e.tc.Value);
				Assert.AreEqual("FOO", e.tA.Value);
				Assert.AreEqual("BAR", e.tB.Value);
				Assert.AreEqual("", e.tC.Value);

				e.ta.Value = "hehe";
				e.tb.Value = "haha";
				e.tc.Value = "hoho";
				e.tA.Value = "hEhE";
				e.tB.Value = "hAhA";
				e.tC.Value = "hOhO";

				root.StepFrameJS();

				Assert.AreEqual("hehe", e.mirror_a.Value);
				Assert.AreEqual("bar", e.mirror_b.Value);
				Assert.AreEqual("hoho", e.mirror_c.Value);

				Assert.AreEqual("hEhE", e.A);
				Assert.AreEqual("BAR", e.B);
				Assert.AreEqual("hOhO", e.C);

				e.changeThingsUp.Perform();
				root.StepFrameJS();
				Assert.AreEqual("foo++", e.ta.Value);
				Assert.AreEqual("bar++", e.tb.Value);
				Assert.AreEqual("hoho", e.tc.Value);

				Assert.AreEqual("foo++", e.mirror_a.Value);
				Assert.AreEqual("bar++", e.mirror_b.Value);
				Assert.AreEqual("moo++", e.mirror_c.Value);
			}
		}

		[Test]
		public void Simple()
		{
			var e = new UX.DataBinding.SimpleBindings();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(true, e.TheWhile.Value);
				Assert.AreEqual("hello", e.TheText.Value);
				Assert.AreEqual(200, e.TheRange.Value);
				Assert.AreEqual(float4(1,0,0,1), e.TheText.TextColor);

				e.CallNext.Perform();
				root.StepFrameJS();
				Assert.AreEqual(false, e.TheWhile.Value);
				Assert.AreEqual("goodbye", e.TheText.Value);
				Assert.AreEqual(100, e.TheRange.Value);
				Assert.AreEqual(float4(0,1,0,1), e.TheText.TextColor);
			}
		}
		
		[Test]
		public void Object()
		{
			var e = new UX.DataBinding.ObjectBindings();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(true, e.TheWhile.Value);
				Assert.AreEqual("hello", e.TheText.Value);
				Assert.AreEqual(200, e.TheRange.Value);
				Assert.AreEqual(float4(1,0,0,1), e.TheText.TextColor);

				e.CallNext.Perform();
				root.StepFrameJS();
				Assert.AreEqual(false, e.TheWhile.Value);
				Assert.AreEqual("goodbye", e.TheText.Value);
				Assert.AreEqual(100, e.TheRange.Value);
				Assert.AreEqual(float4(0,1,0,1), e.TheText.TextColor);

				e.CallNext.Perform();
				root.StepFrameJS();
				Assert.AreEqual(true, e.TheWhile.Value);
				Assert.AreEqual("oop", e.TheText.Value);
				Assert.AreEqual(50, e.TheRange.Value);
				Assert.AreEqual(float4(0,0,1,1), e.TheText.TextColor);
			}
		}
		
		[Test]
		public void NodeName()
		{
			var p = new UX.DataBinding.NodeName();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( p.A, p.Bind.Node );
				Assert.AreEqual( p.A, p.Bind.Visual );
				Assert.AreEqual( p.B, p.Bind.Trigger );
				
				//https://github.com/fusetools/fuselibs-private/issues/3538
				//Assert.AreEqual( p.C, p.SBind.Node );
				Assert.AreEqual( p.B, p.SBind.Trigger );
			}
		}
		
		[Test]
		public void NodeDefer()
		{
			var p = new UX.DataBinding.NodeDefer();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( null, p.Bind.Node ); //not yet
				
				p.B.Value = true;
				root.PumpDeferred();
				Assert.AreEqual( p.A, p.Bind.Node );
			}
		}
		
		[Test]
		public void FileConversion()
		{
			var p = new UX.DataBinding.FileConversion();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual( "Hello", p.B.File.ReadAllText() );
			}
		}
		
		[Test]
		public void Failed()
		{
			var p = new UX.DataBinding.Failed();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				Assert.AreEqual("hi",p.T.Value);
				Assert.AreEqual("", p.TF.Value);
				Assert.AreEqual(0, TriggerProgress(p.WF));
				
				p.CallFail.Perform();
				root.StepFrameJS();
				Assert.AreEqual("",p.T.Value);
				Assert.AreEqual("nope", p.TF.Value);
				Assert.AreEqual(1, TriggerProgress(p.WF));
				
				p.CallRestore.Perform();
				root.StepFrameJS();
				Assert.AreEqual("bye",p.T.Value);
				Assert.AreEqual("", p.TF.Value);
				Assert.AreEqual(0, TriggerProgress(p.WF));
			}
		}
	}
}

namespace FuseTest
{
	public class FileHolder : Fuse.Behavior
	{
		public FileSource File { get; set; }
	}	
}
