using Uno;

namespace Fuse.Triggers.Actions
{
	/**
		Calls a JavaScript function when a trigger is activated.

		## Example
		
		This example calls the JavaScript function `someJSFunction` when a @Button is @Clicked.

			<JavaScript>
				var someJSFunction = function () {
					console.log("some function called");
				}
				module.exports = { someJSFunction: someJSFunction };
			</JavaScript>
			
			<Button Text="Do something">
				<Clicked>
					<Callback Handler="{someJSFunction}"/>
				</Clicked>
			</Button>
	*/
	public class Callback : TriggerAction
	{
		/** @advanced */
		public Action Action { get; set; }
		
		/** The JavaScript function to be called */
		public event VisualEventHandler Handler;
		
		protected override void Perform(Node target)
		{
			if (Action != null)
				Action();
				
			if (Handler != null)
			{
				var visual = target.FindByType<Visual>();
				// HACK: Users use 'args.sender' to identify which visual people
				// for instance clicked. To restore this behavior, lie about the
				// sender here, and pass `visual` instead.
				Handler(visual, new VisualEventArgs(visual));
			}
		}
	}
}
