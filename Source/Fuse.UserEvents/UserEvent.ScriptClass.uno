using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse
{
	public partial class UserEvent
	{
		static UserEvent()
		{
			ScriptClass.Register(typeof(UserEvent),
				new ScriptMethod<UserEvent>("raise", raise)
			);
		}

		/**
			Raises a UserEvent with an optional set of arguments.
			
			@scriptmethod raise( args )
			
			@param args (Object) _(optional)_ A plain JavaScript object
				representing name-value pairs of arguments to be passed with the
				event. When using a JavaScript function to handle the event
				(via @Fuse.Triggers.OnUserEvent.Handler), this object will be
				passed as the first argument to the handler function.
			
			## Example
			
			Here is a very basic example showing how you can raise a UserEvent
			from JavaScript.
			
				<UserEvent ux:Name="myEvent" />
				
				<JavaScript>
					myEvent.raise();
				</JavaScript>
			
			The following example raises an event with some arguments 5 seconds
			after JavaScript has started executing, and logs its arguments in
			the event handler.
			
				<UserEvent ux:Name="myEvent" />
				<OnUserEvent EventName="myEvent" Handler="{eventHandler}" />
				
				<JavaScript>
					setTimeout(function() {
					
						myEvent.raise({
							userName: "james",
							isAdmin: false
						});
						
					}, 5000);

					function eventHandler(args) {
						console.log("User name: " + args.userName);
						console.log("Is admin: " + args.isAdmin);
					}
					
					module.exports = { eventHandler: eventHandler };
				</JavaScript>
			
		**/
		static void raise(UserEvent n, object[] args)
		{
			if (args.Length == 0)
			{
				n.Raise();
				return;
			}
			
			if (args.Length > 1)
			{
				Fuse.Diagnostics.UserError( "Raise must be called with zero arguments, or one argument defining the arguments to the event", n );
				return;
			}
			
			var so = args[0] as IObject;
			if (so == null)
			{
				Fuse.Diagnostics.UserError( "Raise must be called with a JavaScript object to define name/value pairs", 
					args[0] );
				return;
			}
			
			var keys = so.Keys;
			var evArgs = new Dictionary<string,object>();
			for (int i=0; i < keys.Length; i++)
			{	
				var name = keys[i];
				evArgs[name] = so[name];
			}
			
			n.Raise(evArgs);
		}
	}
}
