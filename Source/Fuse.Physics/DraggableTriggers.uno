using Uno;
using Fuse.Scripting;

namespace Fuse.Physics
{

	public abstract class DraggableTrigger: Fuse.Triggers.Trigger
	{
		public Draggable Draggable { get; set; }
	}

	public class DraggableEventArgs : EventArgs, IScriptEvent
	{
		internal Body Body { get; private set; }
		internal float3 Position { get; private set; }
		public Visual Visual { get { return Body.Visual; } }

		internal DraggableEventArgs(Body body, float3 position)
		{
			Body = body;
			Position = position;
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddObject("position", Position);
		}
	}

	public delegate void DraggableEventHandler(object sender, DraggableEventArgs args);

	public abstract class DraggableEventTrigger: DraggableTrigger
	{
		public event DraggableEventHandler Handler;

		internal void OnTriggered(Body body, float3 position)
		{
			Pulse();

			if (Handler != null)
			{
				var args = new DraggableEventArgs(body, position);
				Handler(this, args);
			}
		}
	}

	public class DragStarted: DraggableEventTrigger
	{
	}

	public class DragEnded: DraggableEventTrigger
	{
	}

}