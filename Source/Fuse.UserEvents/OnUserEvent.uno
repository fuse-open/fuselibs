using Uno.UX;

namespace Fuse.Triggers
{
	public enum OnUserEventFilter
	{
		/** tree-scope on events, only listens to the most immediate ancestor event (of Context) */
		Local,
		/** listens to events coming from anywhere */
		Global,
	}
	
	/**
		Triggers when a @UserEvent is raised.
		
		> *Note:* See [this article](/docs/basics/creating-components#events-userevent)
		> for a more complete explanation of user events.
		
		By default, `OnUserEvent` will only listen for events that are
		declared in one of its ancestor nodes. If you want to listen for
		events coming from anywhere, set the `Filter` property to `Global`.

		`OnUserEvent` also lets you attach a JavaScript handler to the event.

			<OnUserEvent EventName="myEvent" Handler="{myHandler}" />

		The handler function is called with the arguments that were passed
		with the event as a plain JavaScript object.

		## Example

		This example defines a @UserEvent and triggers it when the panel
		is clicked:

			<Panel ux:Name="panel" Color="Blue">
				<UserEvent Name="myEvent"/>
				<OnUserEvent EventName="myEvent">
					<Change panel.Color="Red" DurationBack="0.5" />
				</OnUserEvent>
				<Clicked>
					<RaiseUserEvent EventName="myEvent" />
				</Clicked>
			</Panel>
		
		This example illustrates how you can read the arguments that were
		passed with the event from a JavaScript handler.
		
			<UserEvent ux:Name="myEvent" />
			
			<Panel Color="#123">
				<Clicked>
					<RaiseUserEvent EventName="myEvent">
						<UserEventArg Name="myArgument" StringValue="Some value" />
					</RaiseUserEvent>
				</Clicked>
			</Panel>
			
			<OnUserEvent EventName="myEvent" Handler="{eventHandler}" />
			
			<JavaScript>
				function eventHandler(args) {
					console.log("myEvent raised with argument 'myArgument': " + args.myArgument);
				}
			
				module.exports = { eventHandler: eventHandler };
			</JavaScript>
	
	*/
	public class OnUserEvent : Trigger
	{
		/**
			The name of the event to listen for. This corresponds to @UserEvent.Name
		*/
		public Selector EventName { get; set; }

		OnUserEventFilter _filter = OnUserEventFilter.Local;
		/**
			Controls the scope of the @UserEvents to consider
		*/
		public OnUserEventFilter Filter
		{
			get { return _filter; }
			set { _filter = value; }
		}

		/**
			A handler to call when this event is raised.
		*/
		public event UserEventHandler Handler;

		UserEventDispatch _rootedEvent;
		protected override void OnRooted()
		{
			base.OnRooted();
			if (EventName == null)
			{
				Fuse.Diagnostics.UserError( "OnUserEvent requires a `EventName`", this);
			}
			else
			{
				_rootedEvent = UserEventDispatch.GetByName(EventName);
				_rootedEvent.Raised += OnRaised;
			}
			_scope = null;
		}

		protected override void OnUnrooted()
		{
			if (_rootedEvent != null)
			{
				_rootedEvent.Raised -= OnRaised;
				_rootedEvent = null;
			}
			base.OnUnrooted();
		}

		Visual _scope;
		/*
			The filtering can't be done at Rooting time since the event itself doesn't register itself
			until rooting time, thus we could have an ordering issue. So we defer the first lookup
			to here.
		*/
		void OnRaised(object s, UserEventArgs args)
		{
			if (Filter == OnUserEventFilter.Local)
			{
				if (_scope == null)
				{
					Visual n;
					UserEvent.ScanTree(Parent, EventName, out n);
					_scope = n;
				}

				//only those events from the most recent source
				if (_scope != args.Source)
					return;
			}

			//handler first
			if (Handler != null)
				Handler(this, args);
				
			Pulse();
		}
	}
}
