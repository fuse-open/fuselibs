using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;
using Uno.Threading;

using Fuse.Controls;
using Fuse.Navigation;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class VariousTest : TestBase
	{
		[Test]
		public void FunctionAsDataContext()
		{
			var e = new UX.FunctionAsDataContext();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.hpb.Step1.Perform();
				root.StepFrameJS();

				Assert.AreEqual(true, e.ok.Value);
			}
		}

		[Test]
		public void ExpressionUnits()
		{
			var e = new UX.ExpressionsUnits();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual(e.r1.Offset.X, Size.Percent(20));
				Assert.AreEqual(e.r2.Offset.X, Size.Percent(20));
				Assert.AreEqual(e.r3.Offset.X, Size.Percent(20));
				Assert.AreEqual(e.r4.Offset.X, new Size(20, Unit.Unspecified));
			}
		}

		[Test]
		public void ExplicitBindings()
		{
			var e = new UX.ExplicitBindings();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual((Size)300, e.p1.Height);
				Assert.AreEqual((Size)330, e.p1.Width);
				Assert.AreEqual(Size.Auto, e.p1.X);
				Assert.AreEqual(float4(1,0,1,1), e.p1.Color);
				Assert.AreEqual(float4(1,0,0,1), e.Color);
			}
		}

		[Test]
		public void ClearBindingTest()
		{
			var e = new UX.ClearBindingTest();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				var pages = new List<UX.ClearBindingTestPage>();
				foreach (var c in e.Children)
				{
					var p = c as UX.ClearBindingTestPage;
					if (p != null)
					{
						Assert.AreEqual("123", p.t1.Value);
						Assert.AreEqual("123", p.t2.Value);
						pages.Add(p);
					}
				}

				Assert.AreEqual(1, pages.Count);

				e.CallRemove.Perform();
				root.StepFrameJS();

				foreach (var p in pages)
				{
					Assert.AreEqual("", p.t1.Value);
					Assert.AreEqual("123", p.t2.Value);
				}
			}
		}

		[Test]
		public void ResourceBindingOnGeneric()
		{
			var e = new UX.ResourceBindingOnGeneric();
			using (var root = TestRootPanel.CreateWithChild(e))
				Assert.IsTrue(e.move.Target is Panel);
		}

		[Test]
		public void ObservableSubscribe()
		{
			var e = new UX.ObservableSubscribe();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				//just not throwing is good enough
				root.StepFrameJS();
				e.Parent.Remove(e);
				root.StepFrameJS();
			}
		}

		[Test]
		/* Tests Observable.combine*() */
		public void ObservableCombine()
		{
			var e = new UX.ObservableCombine();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				//just not throwing is good enough
				root.StepFrameJS();
				root.StepFrameJS();

				e.Go.Perform();

				root.StepFrameJS();
				root.StepFrameJS();
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		/* Tests that binding empty Observable to Placeholder text do not throw exception */
		public void Issue2532()
		{
			var e = new UX.Issue2532();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				//just not throwing is good enough
				root.StepFrameJS();
				root.StepFrameJS();
			}
		}

		[Test]
		/* Tests when the values are captured for the deferred JS callbacks */
		public void Issue1995()
		{
			var e = new UX.Issue1995();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("Start", e.T.Value);

				//this assumes the added children start after the `Each`
				((e.C.Children[5] as Visual).Children[0] as FuseTest.Invoke).Perform();
				Assert.AreEqual("Start", e.T.Value); //no immediate change
				//e.Children.Remove(e.C);
				root.StepFrameJS();
				Assert.AreEqual("#4", e.T.Value);
			}
		}

		[Test]
		/* Tests that Node.findData() resolves correctly in JS */
		public void FindData()
		{
			var e = new UX.FindData();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.wt.Value = true;
				root.StepFrameJS();

				Assert.AreEqual("correct", e.t1.Value);
				Assert.AreEqual("correct", e.t2.Value);
				Assert.AreEqual("correct", e.t3.Value);
			}
		}

		// Stuff needed by the OnValueChanged test
		class GetSubscriberCount
		{
			Scripting.Object _observable;

			public GetSubscriberCount(Scripting.Object observable)
			{
				_observable = observable;
			}

			public int Count;

			public void Run()
			{
				Count = (_observable["_subscribers"] as Scripting.Array).Length;
			}
		}

		class GetObservableForPropertyClosure
		{
			public GetObservableForPropertyClosure(Visual visual, string propName)
			{
				if (visual == null)
					throw new ArgumentNullException(nameof(visual));

				_visual = visual;
				_propName = propName;
			}

			readonly Visual _visual;
			readonly string _propName;
			ManualResetEvent _done = new ManualResetEvent(false);
			public Scripting.Object Observable { get; private set; }
			public Fuse.Scripting.JavaScript.ClassInstance ClassInstance;

			public void Wait() { _done.WaitOne(); }

			internal void Run(Scripting.Context context)
			{
				var classInstance = ((Fuse.Scripting.JavaScript.JSContext)context).GetExistingClassInstance(_visual);
				var observableProperty = classInstance.GetObservableProperty(_propName);
				Observable = (Scripting.Object)observableProperty.GetObservable(context).Raw;
				_done.Set();
			}
		}

		static Scripting.Object GetObservableForProperty(Visual e, string propName)
		{
			var closure = new GetObservableForPropertyClosure(e, propName);
			JavaScript.Worker.Invoke(closure.Run);
			closure.Wait();
			return closure.Observable;
		}

		[Test]
		/** Tests that modules and ClassInstances along with their implicit observable backing is
			appropriately disposed, and that Observable.onValueChanged subscribers are removed when 
			modules are disposed */
		public void ModuleLifetime()
		{
			var e = new UX.ModuleLifetime();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				var obs = GetObservableForProperty(e, "Foo");

				// 3 subscriptions from the 3 instances in the each + 1 subscription from
				// the uno side for the implicit property backing = 4 toal
				var getSubscriberCount = new GetSubscriberCount(obs);
				JavaScript.Worker.Invoke(getSubscriberCount.Run);
				root.StepFrameJS();
				Assert.AreEqual(4, getSubscriberCount.Count);

				// Removing one one the items from the each
				e.remove.Perform();
				root.StepFrameJS();

				// Should now only have 2+1=3 subscriptions remaining
				JavaScript.Worker.Invoke(getSubscriberCount.Run);
				root.StepFrameJS();
				Assert.AreEqual(3, getSubscriberCount.Count);

				// Unroot everything
				root.Children.Remove(e);
				root.StepFrameJS();

				// Should now have zero subscribers - none from JS, none 
				// from the implicit property backing
				JavaScript.Worker.Invoke(getSubscriberCount.Run);
				root.StepFrameJS();
				Assert.AreEqual(0, getSubscriberCount.Count);

				// Add it back
				root.Children.Add(e);
				root.StepFrameJS();

				Assert.IsTrue(e.IsRootingCompleted);

				// The old observable should still have zero subscribers, because
				// the observable backing store should be re-created when the node
				// is re-rooted. The old one is now garbage
				JavaScript.Worker.Invoke(getSubscriberCount.Run);
				root.StepFrameJS();
				Assert.AreEqual(0, getSubscriberCount.Count);

				// The new observable should be a distinct object
				var newObs = GetObservableForProperty(e, "Foo");
				Assert.AreNotEqual(obs, newObs);

				// The new observable should have exactly 4 subscribers
				getSubscriberCount = new GetSubscriberCount(newObs);
				JavaScript.Worker.Invoke(getSubscriberCount.Run);
				root.StepFrameJS();
				Assert.AreEqual(4, getSubscriberCount.Count);
			}
		}


		[Test]
		/** Tests that nodes inserted by triggers get the correct data context. */
		public void TriggerDataContext()
		{
			var e = new UX.TriggerDataContext();

			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				int textCount = 0;
				foreach (var c in e.stack.Children)
				{
					var t = c as Text;
					if (t != null)
					{
						textCount++;
						Assert.AreEqual("correct title", t.Value);
					}
				}

				Assert.AreEqual(30, textCount);
			}
		}

		[Test]
		public void MultiDataContext()
		{
			var e = new UX.MultiDataContext();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.IsTrue(e.items.VisualChildCount > 0);
				AssertTextCorrect(e.items);
			}
		}

		static void AssertTextCorrect(Visual v)
		{
			foreach (var c in v.Children)
			{
				var t = c as Text;
				if (t != null)
				{
					Assert.AreEqual("correct", t.Value);
				}
				var x = c as Visual;
				if (x != null) AssertTextCorrect(x);
			}
		}

		[Test]
		/* Tests https://github.com/fusetools/fuselibs-private/issues/2398 */
		public void Issue2398()
		{
			var e = new UX.Issue2398();
		}
		
		[Test]
		/* A variant of the previous test involving Select and a changing Context */
		public void Issue1995Select()
		{
			var e = new UX.Issue1995Select();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("#", e.T.Value);

				e.Call.Perform();
				e.In1.Children.Remove(e.C);
				e.In2.Children.Add(e.C);
				e.Call.Perform();
				Assert.AreEqual("#", e.T.Value);

				root.StepFrameJS();
				Assert.AreEqual("#12", e.T.Value);
			}
		}

		[Test]
		/* Observable.removeAt needs to throw exceptions on out-of-bounds */
		public void Issue2236()
		{
			var e = new UX.Issue2236();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.Go.Perform();
				root.StepFrameJS();
				Assert.AreEqual(true, e.T.Value);
			}
		}

		[Test]
		public void Issue2326()
		{
			var e = new UX.Issue2326();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("100", e.FooString.Value);
				Assert.AreEqual("200", e.SelectBazString.Value);
				Assert.AreEqual("200", e.SelectBarBazString.Value);
				Assert.AreEqual("200", e.BarBazString.Value);
				e.run.Perform();
				root.StepFrameJS();
				Assert.AreEqual("101", e.FooString.Value);
				Assert.AreEqual("201", e.SelectBazString.Value);
				Assert.AreEqual("201", e.SelectBarBazString.Value);
				Assert.AreEqual("201", e.BarBazString.Value);
			}
		}

		[Test]
		public void Issue2350()
		{
			var e = new UX.Issue2350();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(true, e.Container.HasVisualChildren);
				Assert.AreEqual(1, e.Container.VisualChildCount);

				var text = e.Container.GetZOrderChild(0) as Text;
				Assert.AreNotEqual(null, text);
				Assert.AreEqual("Bar", text.Value);
			}
		}

		[Test]
		public void Issue2458()
		{
			var e = new UX.Issue2458();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual(float4(0, 0, 0, 0), e.Rect.Color);

				e.Bar.Perform();
				root.StepFrameJS();
				Assert.AreEqual(float4(0, 1, 0, 1), e.Rect.Color);
			}
		}

		[Test]
		public void ObjectUnwrapping()
		{
			var e = new UX.ObjectUnwrapping();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var someItem = (SomeItem)e.SomeItem;
				Assert.AreEqual("{\"foo\":\"bar\"}", someItem.Text.Value);
			}
		}

		[Test]
		public void Issue2509()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var e = new UX.Issue2509();
				using (var root = TestRootPanel.CreateWithChild(e))
				{
					root.StepFrameJS();

					var diagnostics = dg.DequeueAll();
					Assert.AreEqual(1, diagnostics.Count);
					Assert.Contains("Loading image from file failed.", diagnostics[0].Message);
				}
			}
		}

		[Test]
		[Ignore("https://github.com/fusetools/fuselibs-private/issues/2809")]
		public void PumpMessagesStackOverflow()
		{
			var e = new UX.PumpMessagesStackOverflow();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(10001, e.VisualChildCount);
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void Issue2731()
		{
			var e = new UX.Issue2731();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				root.StepFrameJS();
				root.StepFrameJS();

				Assert.AreEqual(0, e.circle.Color.X);
				Assert.AreEqual(0, e.circle.Color.Y);
				Assert.AreEqual(0, e.circle.Color.Z);
				Assert.AreEqual(1, e.circle.Color.W);
			}
		}

		public class MyClass : Node
		{
			public enum MyEnum
			{
				FooValue,
				BarValue
			}


			MyEnum _test;
			static readonly Selector TestName = "Test";
			[UXOriginSetter("SetTest")]
			public MyEnum Test
			{
				get { return _test; }
				set {
					SetTest(value, null);
				}
			}

			public void SetTest(MyEnum value, IPropertyListener origin)
			{
				_test = value;
				OnPropertyChanged(TestName, origin);
			}
		}

		[Test]
		public void EnumMarshalling()
		{
			var e = new UX.EnumMarshalling();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual(MyClass.MyEnum.FooValue, e.MyClass.Test);
				Assert.AreEqual("FooValue", e.Text.Value);

				e.MyClass.Test = MyClass.MyEnum.BarValue;
				root.StepFrameJS();
				Assert.AreEqual("BarValue", e.Text.Value);
			}
		}

		[Test]
		public void InnerClassDependencies()
		{
			var e = new UX.InnerClassDependencies();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual("foo", e._innerClass._fooText.Value);
				Assert.AreEqual("bar", e._innerClass._barText.Value);
			}
		}

		[Test]
		public void ClassConstructor()
		{
			var p1 = new Panel();
			var p2 = new Panel();
			var e = new UX.ClassConstructor(p1, p2);
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				Assert.AreEqual(p1, ((UX.ClassConstructorBase)e)._a.Children[0]);

				Assert.AreEqual(p1, e._a.Nodes[0]);
				Assert.AreEqual(p2, e._b.Nodes[0]);
			}
		}

		[Test]
		public void DataToResourceCrash()
		{
			var e = new UX.DataToResource.Crash();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("Bar", e.Text.Value);
			}
		}
		
		[Test]
		public void OptionalExplicitTest()
		{
			var e = new UX.OptionalExplicit();
			var root = TestRootPanel.CreateWithChild(e);
			root.StepFrameJS();
			Assert.AreEqual("1", e.t.Value);
			Assert.AreEqual("1", e.q.t.Value);
		}
	}
}
