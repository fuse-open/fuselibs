using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Scripting;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class TreeObservableTest : TestBase
	{
		[Test]
		public void Set()
		{
			var e = new UX.TreeObservable.Set();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("initial", e.t.Value);
				e.setDeep.Perform();
				root.StepFrameJS();
				Assert.AreEqual("changed", e.t.Value);
			}
		}

		[Test]
		public void SetCyclic()
		{
			var e = new UX.TreeObservable.SetCyclic();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("foo", e.t1.Value);
				Assert.AreEqual("foo", e.t2.Value);
				e.setDeep.Perform();
				root.StepFrameJS();
				Assert.AreEqual("bar", e.t1.Value);
				Assert.AreEqual("bar", e.t2.Value);
				e.replaceCycle2.Perform();
				root.StepFrameJS();
				Assert.AreEqual("baz", e.t1.Value);
				Assert.AreEqual("baz", e.t2.Value);
			}
		}

		[Test]
		public void Array()
		{
			var e = new UX.TreeObservable.Array();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("1,2,3", GetRecursiveText(e));

				e.setElement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,2,1337", GetRecursiveText(e));

				e.addElement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,2,1337,123", GetRecursiveText(e));

				e.addElement.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,2,1337,123,123", GetRecursiveText(e));

				e.insertAt.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,333,2,1337,123,123", GetRecursiveText(e));

				e.removeAt.Perform();
				root.StepFrameJS();
				Assert.AreEqual("1,333,2,1337,123", GetRecursiveText(e));
			}
		}

		[Test]
		public void TwoWayArray()
		{
			var e = new UX.TreeObservable.TwoWayArray();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				Assert.AreEqual("1,2,3", e.OC.JoinValues());

				e.s4.Add();
				root.StepFrameJS();
				Assert.AreEqual("1,2,3,4", e.OC.JoinValues());

				e.s1.Remove();
				root.StepFrameJS();
				Assert.AreEqual("2,3,4", e.OC.JoinValues());

				e.s1.Add();
				e.s2.Remove();
				e.s3.Remove();
				e.s4.Remove();
				root.StepFrameJS();
				Assert.AreEqual("1", e.OC.JoinValues());
			}
		}

		[Test]
		[Ignore("https://github.com/fuse-open/fuselibs/issues/671", "Android || iOS")]
		public void TwoWayObject()
		{
			var e = new UX.TreeObservable.TwoWayObject();
			using(var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				root.StepFrameJS();
				Assert.AreEqual("foo", e.t.StringValue);
				Assert.AreEqual("foo", e.ti.Value);

				e.ti.Value = "bar";
				root.StepFrameJS();

				Assert.AreEqual("bar", e.t.StringValue);
				Assert.AreEqual("bar", e.ti.Value);
				
				root.StepFrameJS();
				Assert.AreEqual("True", e.wasChanged.StringValue);
			}
		}
	}
}
