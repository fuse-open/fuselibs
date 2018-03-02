using Uno;
using Uno.UX;
using Uno.Testing;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Navigation;

using FuseTest;

namespace Fuse.Models.Test
{
	public class ModelTest : ModelTestBase
	{
		[Test]
		public void UpdateDisconnectedAfterPromise()
		{
			var e = new UX.Model.UpdateDisconnectedAfterPromise();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				e.disconnect.Perform();
				root.StepFrameJS();
				
				e.resolvePromise.Perform();
				root.StepFrameJS();
				
				e.connect.Perform();
				root.StepFrameJS();
				Assert.AreEqual("foo", e.promisedValue.StringValue);
			}
		}

		[Test]
		public void ArgsSingleVectorArg()
		{
			var e = new UX.Model.Args.SingleVectorArg();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var extObjVec = (Fuse.Scripting.External) e.result.ObjectValue;
				Assert.AreEqual(e.vec, extObjVec.Object);
			}
		}

		[Test]
		public void ArgsEach()
		{
			var e = new UX.Model.Args.Each();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("(foo),(bar),(baz)", GetRecursiveText(e));
				Assert.AreEqual(3, e.innerInstanceCount.Value);
				Assert.AreEqual(1, e.outerInstanceCount.Value);
			}
		}

		[Test]
		public void ArgsScrollView()
		{
			var e = new UX.Model.Args.ScrollView();
			using (var root = TestRootPanel.CreateWithChild(e, int2(200)))
			{
				root.StepFrameJS();
				Assert.AreEqual(0, e.scrollView.ScrollPosition.Y);

				e.doScroll.Perform();
				root.StepFrameJS();
				Assert.AreEqual(1337, e.scrollView.ScrollPosition.Y);
				Assert.AreEqual(1, e.instanceCount.Value);
			}
		}

		[Test]
		public void ArgsSingle()
		{
			var e = new UX.Model.Args.Single();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("hello!", e.output.StringValue);
				Assert.AreEqual(1, e.instanceCount.Value);

				e.input.Value = "goodbye";
				root.StepFrameJS();
				Assert.AreEqual("goodbye!", e.output.StringValue);
				Assert.AreEqual(2, e.instanceCount.Value);
			}
		}
		
		[Test]
		public void NestedArray()
		{
			var e = new UX.Model.NestedArray();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("", GetRecursiveText(e));
				e.push.Perform(); // Throws if test fails
				root.StepFrameJS();
				Assert.AreEqual("0,1,2", GetRecursiveText(e));
			}
		}

		[Test]
		public void ArrayParentMeta()
		{
			var e = new UX.Model.ArrayParentMeta();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("foo,bar,baz", GetRecursiveText(e));
				e.step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual("foo,baz", GetRecursiveText(e));
				e.step2.Perform();
				root.StepFrameJS(); // Throws if test fails
				Assert.AreEqual("baz,baz", GetRecursiveText(e));
			}
		}

		[Test]
		public void ReplaceAt() 
		{
			var e = new UX.Model.ReplaceAt();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.replaceTodo.Perform();
				root.StepFrameJS();
				e.changeFeedTheCat.Perform();
				root.StepFrameJS(); // Throws if test fails
			}
		}
		
		[Test]
		public void Async()
		{
			var e = new UX.Model.Async();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("10", e.t1.Value);
				e.doSomething.Perform();
				root.StepFrameJS();
				root.StepFrameJS();
				Assert.AreEqual("50", e.t1.Value);
			}
		}

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

				e.callReplace.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "4,8,2,5,1", e.oc.JoinValues() );

				e.callSort.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "1,2,4,5,8", e.oc.JoinValues() );
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
				Assert.AreEqual("1,3,1", GetDudZ(e));
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
		public void Loop()
		{
			var e = new UX.Model.Loop();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "%", e.a.UseValue );
				Assert.AreEqual( "%", e.b.UseValue );
				Assert.AreEqual( "%", e.c.UseValue );

				Assert.AreEqual( "5", e.q.UseValue );
				Assert.AreEqual( "5", e.r.UseValue );
			}
		}
		
		[Test]
		public void Loop2()
		{
			var e = new UX.Model.Loop2();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("Q5", GetRecursiveText(e) );
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
				root.StepFrameJS();
				Assert.AreEqual("c", e.a.UseValue);
				Assert.AreEqual("b", e.b.UseValue);

				e.callStep2.Perform();
				root.StepFrameJS();
				Assert.AreEqual("c", e.a.UseValue);
				Assert.AreEqual("d", e.b.UseValue);

				e.callStep3.Perform();
				root.StepFrameJS();
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
				Assert.AreEqual( 11, e.u.Load );
				Assert.AreEqual( 10, e.u.DefaultFromJS );

				e.u.Value = "loppy";
				root.StepFrameJS();
				Assert.AreEqual( "loppy", e.u.v.StringValue );
				Assert.AreEqual( 0, e.u.id.Value );

				e.u.callIncrLoad.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 12, e.u.Load );
			}
		}

		[Test]
		public void Accessor()
		{
			var e = new UX.Model.Accessor();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( 110, e.v.Value );
				Assert.AreEqual( 10, e.r.Value );
				Assert.AreEqual( 220, e.d.Value );

				e.v.Value = 115;
				root.StepFrameJS();
				Assert.AreEqual( 115, e.v.Value );
				Assert.AreEqual( 15, e.r.Value );
				Assert.AreEqual( 230, e.d.Value );

				e.callIncr.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 116, e.v.Value );
				Assert.AreEqual( 16, e.r.Value );
				Assert.AreEqual( 232, e.d.Value );
			}
		}

		[Test]
		public void UseCase1()
		{
			var e = new UX.Model.UseCase1();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual( "one,two,three,four,five", GetRecursiveText(e.a) );
				Assert.AreEqual( "five", GetText(e.s) );

				var two = e.a.FindNodeByName( "two" ) as UMUItem;
				two.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "five,two", GetText(e.s) );

				var five = e.a.FindNodeByName( "five" ) as UMUItem;
				five.callRemove.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "two", GetText(e.s) );
			}
		}

		[Test]
		public void Each()
		{
			var e = new UX.Model.Each();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual( "three,two,one", GetDudZ(e.a));
				Assert.AreEqual( "three,two,one", GetDudZ(e.b));
			}
		}

		[Test]
		public void NestedAccessor()
		{
			var e = new UX.Model.NestedAccessor();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( 110, e.v.Value );
				Assert.AreEqual( 10, e.r.Value );
				Assert.AreEqual( -10, e.d.Value );

				e.v.Value = 115;
				root.StepFrameJS();
				Assert.AreEqual( 115, e.v.Value );
				Assert.AreEqual( 15, e.r.Value );
				Assert.AreEqual( -15, e.d.Value );

				e.callIncr.Perform();
				root.StepFrameJS();
				Assert.AreEqual( 116, e.v.Value );
				Assert.AreEqual( 16, e.r.Value );
				Assert.AreEqual( -16, e.d.Value );
			}
		}

		[Test]
		public void Test1()
		{
			var e = new UX.Model.Test1();
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
		public void ListOrder()
		{
			var e = new UX.Model.ListOrder();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual( "2,3", e.oc.JoinValues() );
				Assert.AreEqual( 0, e.oc.Log.Count);

				e.callAdd.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "2,3,5", e.oc.JoinValues() );
				Assert.AreEqual( 1, e.oc.Log.Count );
				Assert.AreEqual( ObservableCollector.LogType.Add, e.oc.Log[0].Type );
				Assert.AreEqual( 5, e.oc.Log[0].Value );

				e.oc.Log.Clear();
				e.callInsert.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "2,6,3,5", e.oc.JoinValues() );
				Assert.AreEqual( 1, e.oc.Log.Count );
				Assert.AreEqual( ObservableCollector.LogType.InsertAt, e.oc.Log[0].Type );
				Assert.AreEqual( 6, e.oc.Log[0].Value );
				Assert.AreEqual( 1, e.oc.Log[0].Index );

				e.oc.Log.Clear();
				e.callShift.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "6,3,5", e.oc.JoinValues() );
				Assert.AreEqual( 1, e.oc.Log.Count );
				Assert.AreEqual( ObservableCollector.LogType.RemoveAt, e.oc.Log[0].Type );
				Assert.AreEqual( 0, e.oc.Log[0].Index );
			}
		}

		[Test]
		public void Promise()
		{
			var e = new UX.Promise();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("kaka", e.p.Value);

				root.StepFrameJS();
				Assert.AreEqual("yay!", e.t.Value);

				e.changePromise.Perform();
				root.StepFrameJS();
				Assert.AreEqual("yay!", e.t.Value);

				e.resolveNow.Perform();
				root.StepFrameJS();
				Assert.AreEqual("hoho!", e.t.Value);
			}
		}

		[Test]
		public void EmptyList()
		{
			var e = new UX.Model.EmptyList();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				var oc = e.collector1.Children;
				var poc = e.collector2.Children;
				root.StepFrameJS();
				Assert.AreEqual("1,2,3", e.oc.JoinValues());
				Assert.AreEqual("3,4,5", e.poc.JoinValues());
				Assert.AreEqual(4, oc.Count);
				Assert.AreEqual(4, poc.Count);
				e.callEmpty.Perform();
				e.callEmptyPromise.Perform();
				root.StepFrameJS();
				Assert.AreEqual("", e.oc.JoinValues());
				Assert.AreEqual("", e.poc.JoinValues());
				Assert.AreEqual(1, oc.Count);
				Assert.AreEqual(1, poc.Count);
			}
		}

		[Test]
		public void MultiCounter()
		{
			var e = new UX.Model.MultiCounter();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var oc = e.counterCollector.Children;
				Assert.AreEqual(2, oc.Count);

				var counter1 = oc[1] as UX.Model.Counter;
				Assert.AreNotEqual(null, counter1);

				Assert.AreEqual("0", counter1.counter.Value);

				counter1.callIncrement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1", counter1.counter.Value);

				e.callAddCounter.Perform();
				root.StepFrameJS();
				Assert.AreEqual(3, oc.Count);

				var counter2 = oc[2] as UX.Model.Counter;
				Assert.AreNotEqual(null, counter2);

				Assert.AreEqual("0", counter2.counter.Value);

				counter2.callIncrement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1", counter2.counter.Value);

				counter2.callIncrement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("2", counter2.counter.Value);

			}
		}

		[Test]
		public void MutatePages()
		{
			var e = new UX.Model.MutatePages();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				var children = ChildrenOfType<Visual>(e.navigator);
				Assert.AreEqual(1, children.Count);
				Assert.OfType<UX.Model.MainPage>(children[0]);

				e.pushPage.Perform();
				root.StepFrameJS();

				var childrenAfterPush = ChildrenOfType<Visual>(e.navigator);
				Assert.AreEqual(2, childrenAfterPush.Count);
				Assert.OfType<UX.Model.MainPage>(childrenAfterPush[0]);
				Assert.OfType<UX.Model.DetailPage>(childrenAfterPush[1]);

				e.popPage.Perform();
				root.StepFrameJS();

				Assert.OfType<UX.Model.MainPage>(e.navigator.Active);
			}
		}

		[Test]
		public void NonPrototypeMethod()
		{
			var e = new UX.Model.NonPrototypeMethod();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				
				for(var i = 0; i < 5; ++i)
				{
					Assert.AreEqual(i, e.v.Value);
					e.increment.Perform();
					root.StepFrameJS();
				}
			}
		}

		[Test]
		public void MultiParent()
		{
			var e = new UX.Model.MultiParent();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				Assert.AreEqual("1337", GetRecursiveText(e.listParent));

				e.step1.Perform();
				root.StepFrameJS();

				Assert.AreEqual("1337", GetRecursiveText(e.listParent));
				Assert.AreEqual(1337, e.field.Value);

				e.step2.Perform();
				root.StepFrameJS();

				Assert.AreEqual("1337", GetRecursiveText(e.listParent));
				Assert.AreEqual(0, e.field.Value);

				e.step3.Perform();
				root.StepFrameJS();

				Assert.AreEqual("1337,123", GetRecursiveText(e.listParent));
			}
		}

		[Test]
		public void ThrowFromGetter()
		{
			using (var dg = new RecordDiagnosticGuard())
			{
				var e = new UX.Model.ThrowFromGetter();
				using (var root = TestRootPanel.CreateWithChild(e))
				{
					root.StepFrameJS();
				}

				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				var se = (Fuse.Scripting.ScriptException) diagnostics[0].Exception;
				Assert.Contains("THROWN_FROM_GETTER", se.Message);
			}
		}

		[Test]
		public void ParentLoop()
		{
			var e = new UX.Model.ParentLoop();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.detachCycle.Perform();
				root.StepFrameJS();

				e.attachCycle.Perform();
				root.StepFrameJS();
				
				e.changeCycleData.Perform();
				root.StepFrameJS();

				// There are no assertions, since failure is triggered by a stack overflow in the JavaScript VM
			}
		}

		[Test]
		public void DisconnectOnUpdate()
		{
			var e = new UX.Model.DisconnectOnUpdate();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.step1.Perform();
				root.StepFrameJS();

				e.step2.Perform();
				root.StepFrameJS();
			}
		}

		static List<T> ChildrenOfType<T>(Visual n) where T : Node
		{
			var l = new List<T>();
			foreach (var child in n.Children)
			{
				var m = child as T;
				if (m != null)
					l.Add(m);
			}
			return l;
		}
	}
}
