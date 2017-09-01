using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse
{
	public class UserEventArgs : EventArgs, IScriptEvent
	{
		internal UserEventDispatch Dispatch { get; private set; }
		
		public Selector Name 
		{	
			get { return Dispatch.Name; }
		}
		
		public Node Source { get; private set; }
		
		/** May be null if there are no arguments */
		public Dictionary<string, object> Args { get; private set; }
		
		internal UserEventArgs(UserEventDispatch dispatch, Node source, Dictionary<string,object> args = null)
		{
			Dispatch = dispatch;
			Source = source;
			Args = args;
		}
		
		internal void Raise()
		{
			Dispatch.OnRaised(this);
		}
		
		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString("name", Dispatch.Name);
			if (Args != null)
			{
				foreach(var m in Args)
					s.AddObject(m.Key, m.Value);
			}
		}
	}
	
	public delegate void UserEventHandler(object sender, UserEventArgs args);
	
	class UserEventDispatch
	{
		static Dictionary<Selector,UserEventDispatch> _userEvents = 
			new Dictionary<Selector,UserEventDispatch>();
		
		public event UserEventHandler Raised;
		
		public Selector Name { get; private set; }
		
		internal static UserEventDispatch GetByName(Selector name)
		{
			UserEventDispatch current;
			if (_userEvents.TryGetValue(name, out current))
				return current;
				
			var ue = new UserEventDispatch();
			ue.Name = name;
			_userEvents[name] = ue;
			return ue;
		}
		
		public void Raise(Node source, Dictionary<string,object> args = null)
		{
			var m = new UserEventArgs(this, source, args);
			UpdateManager.AddDeferredAction(m.Raise);
		}
		
		internal void DirectRaise(Node source = null, Dictionary<string,object> args = null)
		{
			var m = new UserEventArgs(this, source, args);
			OnRaised( m );
		}
		
		internal void OnRaised(UserEventArgs args)
		{
			if (Raised != null)	
				Raised(this, args);
		}
	}

	/**
		Defines a custom event that can be raised by a component and responded
		to by a user of that component.
		
		> *Note:* See [this article](/docs/basics/creating-components#events-userevent)
		> for a more complete explanation of user events.

		User events are attached to the node they are declared in, and only that
		node and its children can raise and handle the event.
		
		## Usage
		
		We put a @UserEvent at the root of our component class to indicate that it can raise a particular event.
		Where we place our @UserEvent is important, since a node has to be in its subtree to raise or handle it.
		
			<Panel ux:Class="MyComponent">
				<UserEvent ux:Name="myEvent" />
			</Panel>
		
		This creates an event named `myEvent`.
		
		>**Note:** To make a @UserEvent that can be raised or handled from anywhere in the app, declare it on the root @App node, like this:
		>
		>```
		><App>
		> 	<UserEvent ux:Name="myGlobalEvent" />
		> 	<!-- The rest of our app goes here -->
		></App>
		>```
		
		
		We can now use @RaiseUserEvent to raise the event from UX.
		
			<Panel ux:Class="MyComponent">
				<UserEvent ux:Name="myEvent" />
		
				<Clicked>
					<RaiseUserEvent EventName="myEvent" />
				</Clicked>
			</Panel>
		
		Or we can raise it from JavaScript.
		
			<Panel ux:Class="MyComponent">
				<UserEvent ux:Name="myEvent" />
		
				<JavaScript>
					setTimeout(function() {
						myEvent.raise();
					}, 5000);
				</JavaScript>
			</Panel>
		
		When we instantiate our component, we can respond to its events using the @OnUserEvent trigger.
		
			<MyComponent>
				<OnUserEvent EventName="myEvent">
					<!-- Actions/animators go here -->
				</OnUserEvent>
			</MyComponent>
		
		Note that we are referencing our @UserEvent by name even though it is declared outside of our current scope.
		We can do this because `EventName` refers to the `Name` of the event. Setting `ux:Name` also sets `Name`, which means that in this example, the `Name` will be `myEvent`.
		The actual instance of @UserEvent will be resolved at runtime.
		
		We can also handle events in JavaScript.
		
			<JavaScript>
				function eventHandler() {
					//do something
				}
		
				module.exports = { eventHandler: eventHandler };
			</JavaScript>
		
			<MyComponent>
				<OnUserEvent EventName="myEvent" Handler="{eventHandler}"/>
			</MyComponent>
		
		We can pass arguments when raising an event.
		
			myEvent.raise({
				userName: "james",
				isAdmin: false
			});
		
		This is also possible when raising the event from UX.
		
			<RaiseUserEvent EventName="myEvent">
				<UserEventArg Name="userName" StringValue="james" />
				<UserEventArg Name="isAdmin" BoolValue="false" />
			</RaiseUserEvent>
		
		The arguments are then passed to the event handler.
		
			<JavaScript>
				function eventHandler(args) {
					console.log("Username: " + args.userName + ", Is admin: " + args.isAdmin);
				}
		
				module.exports = { eventHandler: eventHandler };
			</JavaScript>
		
			<OnUserEvent EventName="myEvent" Handler="{eventHandler}" />
		


		@see fuse/triggers/actions/raiseuserevent
		@see fuse/userevent/raise_09a1af86
		@see fuse/triggers/onuserevent
	*/
	public partial class UserEvent : Behavior
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if (Name == null)
			{
				Fuse.Diagnostics.UserError( "UserEvent requires a Name", this );
				return;
			}
			
			Dispatch = UserEventDispatch.GetByName(Name);
		}

		protected override void OnUnrooted()
		{
			Dispatch = null;
			base.OnUnrooted();
		}
		
		internal UserEventDispatch Dispatch;

		/**
			Find the most recent definition of this event in the tree.
			@return the found event, null if none
		*/
		internal static UserEvent ScanTree(Node at, Selector name, out Visual visual)
		{
			while(at != null)
			{
				var v = at as Visual;
				if (v != null)
				{
					for (var ue = v.FirstChild<UserEvent>(); ue != null; ue = ue.NextSibling<UserEvent>())
					{
						if (ue.Name == name)
						{
							visual = v;
							return ue;
						}
					}
				}
				at = at.ContextParent;
			}
			
			visual = null;
			return null;
		}
		
		public void Raise(Dictionary<string,object> args = null)
		{
			if (Dispatch == null)
			{
				Fuse.Diagnostics.InternalError( "Trying to Raise on unrooted UserEvent", this );
				return;
			}
			
			Dispatch.Raise(Parent, args);
		}
		
		public static void RaiseEvent(Visual from, Selector name, Dictionary<string,object> args = null)
		{
			Visual n;
			var ev = ScanTree(from, name, out n);
			if (ev == null)
			{
				Fuse.Diagnostics.InternalError( "Unknown event: " + name );
				return;
			}
			
			ev.Raise(args);
		}
	}
}
