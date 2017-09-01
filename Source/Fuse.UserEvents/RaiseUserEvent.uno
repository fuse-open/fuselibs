using Uno.Collections;
using Uno.UX;

namespace Fuse.Triggers.Actions
{
	/**
		Raises a UserEvent specified by name.

		The @UserEvent must exist higher up in the tree than this action.

		> *Note:* See [this article](/docs/basics/creating-components#events-userevent)
		> for a more complete explanation of user events.

		# Examples
		
		The following example shows a button which raises a @UserEvent when
		clicked.
			
			<UserEvent ux:Name="myEvent" />
			<Button>
				<Clicked>
					<RaiseUserEvent EventName="myEvent" />
				</Clicked>
			</Button>
		
		You can also pass arguments using @UserEventArg.
		When using a JavaScript function to handle the event, the arguments will
		be passed to that function.
		
			<UserEvent ux:Name="myEvent" />
			<Button>
				<Clicked>
					<RaiseUserEvent EventName="myEvent">
						<UserEventArg Name="name" StringValue="james" />
						<UserEventArg Name="isAdmin" BoolValue="false" />
					</RaiseUserEvent>
				</Clicked>
			</Button>
	*/
	public class RaiseUserEvent : TriggerAction
	{
		Selector _eventName;
		/**
			The name of the even to raise. This corresponds to the @UserEvent.Name property.
		*/
		public Selector EventName 
		{ 
			get { return _eventName; }
			set
			{
				_eventName = value;
				_event = null;
			}
		}
		
		//caches found Event to avoid multiple lookups	
		Node _eventTarget;
		UserEvent _event;
		
		IList<UserEventArg> _args;
		[UXPrimary]
		/**
			The list of arguments to pass along with the event. Generally this is specified as a list of
			@UserEventArg children.
		*/
		public IList<UserEventArg> ArgList
		{
			get
			{
				if (_args == null)
					_args = new List<UserEventArg>();
				return _args;
			}
		}
		
		protected override void Perform(Node target)
		{
			if (_event == null || _eventTarget != target)
			{
				Visual n;
				_event = UserEvent.ScanTree(target, EventName, out n);
				_eventTarget = target;
			}
				
			if (_event == null)
				Fuse.Diagnostics.UserError( "no UserEvent found: " + EventName, this );
			else
				_event.Raise(ConvertArgs());
		}
		
		Dictionary<string,object> ConvertArgs()
		{
			if (_args == null || _args.Count == 0)
				return null;
				
			var d = new Dictionary<string,object>();
			foreach (var arg in _args)
			{
				d[arg.Name] = arg.Value;
			}
			return d;
		}
	}
	
	/**
		Represents an argument to be passed with @RaiseUserEvent
		
		A user event may also include a number of arguments that can be
		read from JavaScript.

		UserEventArg accepts `IntValue`, `FloatValue`, `StringValue` or
		`BoolValue`.

		> *Note:* See [this article](/docs/basics/creating-components#events-userevent)
		for a more complete explanation of user events.

		## Example
		
		The following example shows a @Button that, when clicked, raises a
		user event with the argument `message`, which has the value
		`Hello from UX!`.

			<UserEvent ux:Name="myEvent" />
			<Button Text="Raise event with message">
				<Clicked>
					<RaiseUserEvent EventName="myEvent">
						<UserEventArg Name="message" StringValue="Hello from UX!" />
					</RaiseUserEvent>
				</Clicked>
			</Button>
	*/
	public sealed class UserEventArg: PropertyObject
	{
		/**
			The Name of the argument.
		*/
		public string Name { get; private set; }
		
		[UXConstructor]
		public UserEventArg([UXParameter("Name")] string name)
		{
			Name = name;
		}
		
		/**
			Specifies the generic `object` value of the argument.
		*/
		public object Value { get; set; }
		
		/**
			The @Value as an `int`
		*/
		public int IntValue
		{
			get { return (int)Value; }
			set { Value = value; }
		}
		
		/**
			The @Value as a `float`
		*/
		public float FloatValue
		{
			//force `double` since `float` doesn't serialize to JS
			get { return (float)(double)Value; }
			set { Value = (double)value; }
		}
		
		/**
			The @Value as a `string`
		*/
		public string StringValue
		{
			get { return (string)Value; }
			set { Value = value; }
		}
		
		/**
			The @Value as a `bool`
		*/
		public bool BoolValue
		{
			get { return (bool)Value; }
			set { Value = value; }
		}
	}
}
