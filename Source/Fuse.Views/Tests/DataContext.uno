using Uno;
using Uno.Testing;
using Uno.UX;
using FuseTest;
using Fuse.Reactive;
using Uno.Collections;

namespace Fuse.Views.Test
{
	public class DataContextTest
	{
		[Test]
		public void SetDataStringTest()
		{
			var ux = new Fuse.Views.Test.UX.SetDataString();
			var root = TestRootPanel.CreateWithChild(ux);

			var dataContext = new DataContext(root);
			dataContext.SetDataString("text", "Hello, world!");

			Assert.AreEqual(ux.Text.Value, "Hello, world!");
		}

		[Test]
		public void SetDataJsonTest()
		{
			var ux = new Fuse.Views.Test.UX.SetDataJson();
			var root = TestRootPanel.CreateWithChild(ux);

			var dataContext = new DataContext(root);
			dataContext.SetDataJson("{\"data\":[{\"text\":\"Hello, World!\",\"slider\":13.37,\"switch\":true},{\"text\":\"//// OUTRACKS\",\"slider\":70,\"switch\":false}]}");

			root.StepFrame();

			var child1 = ux.Children[1] as Fuse.Views.Text.UX.Item;
			Assert.AreNotEqual(null, child1);

			Assert.AreEqual("Hello, World!", child1.Text.Value);
			Assert.AreEqual(13.37, child1.Slider.Value);
			Assert.AreEqual(true, child1.Switch.Value);

			var child2 = ux.Children[2] as Fuse.Views.Text.UX.Item;
			Assert.AreNotEqual(null, child2);

			Assert.AreEqual("//// OUTRACKS", child2.Text.Value);
			Assert.AreEqual(70.0, child2.Slider.Value);
			Assert.AreEqual(false, child2.Switch.Value);
		}

		[Test]
		public void SetCallbackTest()
		{
			var ux = new Fuse.Views.Test.UX.SetCallback();
			var root = TestRootPanel.CreateWithChild(ux);
			root.Layout(float2(200.0f));

			var dataContext = new DataContext(root);
			var eventHandler = new CallbackHandler();
			dataContext.SetCallback("run", eventHandler);

			root.StepFrame();
			root.PointerPress(float2(100.0f));
			root.PointerRelease(float2(100.0f));

			Assert.AreNotEqual(null, eventHandler.EventRecord);

			var args = new Dictionary<string,object>();
			foreach (var a in eventHandler.EventRecord.Args)
				args.Add(a.Key, a.Value);

			Assert.AreEqual(100.0, Marshal.ToDouble(args["x"]));
			Assert.AreEqual(100.0, Marshal.ToDouble(args["y"]));
		}

		class CallbackHandler : IEventHandler
		{
			public IEventRecord EventRecord { get; private set;}

			void IEventHandler.Dispatch(IEventRecord e)
			{
				EventRecord = e;
			}
		}
	}
}