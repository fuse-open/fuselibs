using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class SynchronusDataSource: Node, Node.ISiblingDataProvider, IObject
	{
		ContextDataResult ISiblingDataProvider.TryGetDataProvider( DataType type, out object provider )
		{
			provider = this;
			return ContextDataResult.Continue;
		}

		string[] IObject.Keys
		{
			get { return new string[] { "sync_data" }; }
		}

		object IObject.this[string key]
		{
			get { return this; }
		}

		bool IObject.ContainsKey(string key) { return key == "sync_data"; }
	}

	public class UXExpressionsTest : TestBase
	{
 		public class ExpressionTester : Panel
		{
			public string StringAttribute { get; set; }
			public double DoubleAttribute { get; set; }
			public bool BoolAttribute { get; set; }
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void ArrayLookup()
		{
			var e = new UX.ArrayLookup();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				root.StepFrameJS();

				Assert.AreEqual("THIS IS FOO", e.t2.Value);
				Assert.AreEqual("THIS IS BAR", e.t3.Value);

				e.CallChangeObj.Perform();
				root.StepFrameJS();

				Assert.AreEqual("FOO HAS CHANGED", e.t2.Value);
				Assert.AreEqual("BAR HAS CHANGED", e.t3.Value);

				Assert.AreEqual("Hello foo : FOO!", e.t1.Value);

				e.CallInc.Perform();
				root.StepFrameJS();
				root.StepFrameJS();

				Assert.AreEqual("Hello foo : BAR!", e.t1.Value);

				e.CallInc.Perform();
				root.StepFrameJS();

				Assert.AreEqual("Hello bar : BAR!", e.t1.Value);

				e.CallDec.Perform();
				root.StepFrameJS();

				Assert.AreEqual("Hello foo : BAR!", e.t1.Value);

				e.CallDec.Perform();
				root.StepFrameJS();

				Assert.AreEqual("Hello foo : FOO!", e.t1.Value);

				e.CallDec.Perform(); // index = -1 now, but that's fine since its /2 so = 0
				root.StepFrameJS();

				Assert.AreEqual("Hello foo : FOO!", e.t1.Value);
			}
		}

		[Test]
		public void StringAttribute()
		{
			var e = new UX.Expressions2();
			using (var root = TestRootPanel.CreateWithChild(e))
				Assert.AreEqual("Test 1337", e.StringAttribute);
		}

		[Test]
		public void DoubleAttribute()
		{
			var e = new UX.Expressions2();
			using (var root = TestRootPanel.CreateWithChild(e))
				Assert.AreEqual(1337.0, e.DoubleAttribute);
		}

		[Test]
		public void BoolAttribute()
		{
			var e = new UX.Expressions2();
			using (var root = TestRootPanel.CreateWithChild(e))
				Assert.AreEqual(true, e.BoolAttribute);
		}

		[Test]
		public void BasicExpressions()
		{
			var e = new UX.Expressions();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				// Sync data should be available before stepframe
				Assert.AreEqual(e.te1.Value, "Fuse.Reactive.Test.SynchronusDataSource");

				root.StepFrameJS();
				root.StepFrame();
				root.StepFrameJS();
				root.StepFrame();

				Assert.AreEqual((Size)150, e.p1.Width);
				Assert.AreEqual(Size.Percent(50), e.p2.Width);
				Assert.AreEqual(Fuse.Elements.Visibility.Visible, e.p4.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Hidden, e.p5.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Hidden, e.p6.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Collapsed, e.p7.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Hidden, e.p8.Visibility);
				Assert.AreEqual((Size)400, e.p4.Height);
				Assert.AreEqual((Size)100, e.p7.Height);
				Assert.AreEqual((Size)400, e.p8.Height);

				Assert.AreEqual(float4(1,1,0,2), e.p3.Color);

				root.StepFrame();
				Uno.Threading.Thread.Sleep(200);
				root.StepFrame(0.2f);
				root.StepFrameJS();

				Assert.AreEqual(new Size2(Size.Percent(14), Size.Pixels(19)), e.p2.Offset);

				e.B = "8.0";
				root.StepFrame();

				Assert.AreEqual(new Size2(-40, 100), e.p7.Offset);
				Assert.AreEqual(new Size2(50, 20), e.p8.Offset);

				Assert.AreEqual(float4(0, 0.5f, 1, 1), e.ci.Color);


				Assert.AreEqual((Size)1600, e.p4.Height);
				Assert.AreEqual(Size.Percent(200), e.p2.Width);
				Assert.AreEqual((Size)270, e.p1.Width);
				Assert.AreEqual(Fuse.Elements.Visibility.Visible, e.p4.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Visible, e.p5.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Visible, e.p6.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Hidden, e.p7.Visibility);
				Assert.AreEqual(Fuse.Elements.Visibility.Hidden, e.p8.Visibility);

				Assert.AreEqual(50, e.p10.ActualPosition.X);
				Assert.AreEqual(0, e.p10.ActualPosition.Y);

				Assert.AreEqual(0, e.p11.ActualPosition.X);
				Assert.AreEqual(60, e.p11.ActualPosition.Y);

				Assert.AreEqual(50, e.p12.ActualPosition.X);
				Assert.AreEqual(60, e.p12.ActualPosition.Y);

				Assert.AreEqual("Hello, john doe! You have 100 new messages!", e.t1.Value);
				Assert.AreEqual("Hola, FOOBAR! You have 2-ish new fruits!", e.t2.Value);
				Assert.AreEqual("", e.t3.Value);

				Assert.AreEqual(true, e.p5.IsEnabled);
				Assert.AreEqual(false, e.p5.ClipToBounds);

				e.N = "Lol";
				Assert.AreEqual("Hola, LOL! You have 2-ish new fruits!", e.t2.Value);

				Assert.AreEqual("Boolean operators: True, True, True, False, False, False", e.t4.Value);
			}
		}

		[Test]
		public void ParameterFunction() 
		{
			var e = new UX.ParameterFunction();

			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual("723.5 nope", e.t1.Value);
				Assert.AreEqual("", e.t2.Value);

				e.CallStep1.Perform();
				root.StepFrameJS();

				Assert.AreEqual("450 nope", e.t1.Value);
				Assert.AreEqual("", e.t2.Value);

				e.CallStep2.Perform();
				root.StepFrameJS();

				Assert.AreEqual("450 nope", e.t1.Value);
				Assert.AreEqual("150", e.t2.Value);

				e.CallStep3.Perform();
				root.StepFrameJS();

				Assert.AreEqual("200 yeah", e.t1.Value);
				Assert.AreEqual("150", e.t2.Value);
			}
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-private/issues/3854")]
		public void DelayFunction()
		{
			var e = new UX.Expressions();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				root.StepFrame();
				root.StepFrameJS();
				root.StepFrame();

				Assert.AreEqual(new Size2(13, 14), e.p2.Offset);
			}
		}
	}
}
