using Uno;
using Uno.Testing;

using Fuse.Controls;
using FuseTest;
using Fuse.Scripting;

namespace Fuse.Reactive.Test
{
	public class EventBindingTest : TestBase
	{
		public class DummyEventArgs : EventArgs, IScriptEvent
		{
			readonly Node Node;
			internal DummyEventArgs(Node node)
			{
				Node = node;
			}

			void IScriptEvent.Serialize(IEventSerializer s)
			{
				object data;
				if (!Node.TryGetPrimeDataContext(out data))
					throw new Exception( "Missing data" );
				s.AddObject("dataContext", data);
			}
		}

		public delegate void DummyEventHandler(object sender, DummyEventArgs args);

		public sealed class DummyBehavior : Behavior
		{
			public event DummyEventHandler Handler;

			public void Perform()
			{
				if (Handler != null)
					Handler(this, new DummyEventArgs(this) );
			}
		}

		[Test]
		public void SerializeObject()
		{
			var e = new UX.EventBinding.Serialize();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.Run.Perform();
				root.StepFrameJS();

				Assert.AreEqual("\"bar\"-bar", e.Text.Value);
			}
		}
		
		[Test]
		public void StandardData()
		{
			var e = new UX.EventBinding.Data();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				
				e.goWith.Perform();
				e.c.FirstChild<FuseTest.Invoke>().Perform();
				for (var c = e.a.FirstChild<Panel>(); c != null; c = c .NextSibling<Panel>()) 
					c.FirstChild<FuseTest.Invoke>().Perform();
				root.StepFrameJS();
				
				Assert.AreEqual( "si-la-one-two-", e.r.StringValue );
			}
		}
	}
}
