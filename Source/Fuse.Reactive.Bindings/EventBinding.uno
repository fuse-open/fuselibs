using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Reactive
{
	/**	 
		Event bindings allows binding events to to JavaScript functions.

		@topic Event binding

		You can hook up event handlers to call JavaScript functions with similar syntax to data bindings:

			<JavaScript>
			    module.exports = {
			        clickHandler: function (args) {
			            console.log("I was clicked: " + JSON.stringify(args));
			        }
			    };
			</JavaScript>
			<Button Clicked="{clickHandler}" Text="Click me!" />

		For more information, see @DataBinding.
	*/
	public class EventBinding: ExpressionBinding
	{
		[UXConstructor]
		public EventBinding([UXParameter("Key"), UXDataScope] IExpression key): base(key)
		{
		}

		IEventHandler _eventHandler;

		List<EventRecord> _queuedEvents;

		void ProcessQueuedEvents()
		{
			if (_eventHandler != null && _queuedEvents != null)
			{
				var events = _queuedEvents;
				_queuedEvents = null;

				for (int i = 0; i < events.Count; i++)
					_eventHandler.Dispatch(events[i]);
			}
		}

		internal override void NewValue(object obj)
		{
			_eventHandler = obj as IEventHandler;
			ProcessQueuedEvents();
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_eventHandler = null;
			_queuedEvents = null;
		}

		public void OnEvent(object sender, Uno.EventArgs args)
		{
			if (Parent == null) return;

			var e = new EventRecord(args as Scripting.IScriptEvent, sender as Node);

			if (_eventHandler != null)
			{
				_eventHandler.Dispatch(e);
			}
			else
			{
				if (_queuedEvents == null)
					_queuedEvents = new List<EventRecord>();

				_queuedEvents.Add(e);
			}
		}
	}
}
