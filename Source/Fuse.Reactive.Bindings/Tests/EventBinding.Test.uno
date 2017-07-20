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
				s.AddObject("dataContext", Node.GetFirstData());
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
			var e = new UX.EventBinding();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();
				e.Run.Perform();
				root.StepFrameJS();

				Assert.AreEqual("\"bar\"", e.Text.Value);
			}
		}
	}
}
