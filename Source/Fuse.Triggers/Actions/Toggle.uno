

namespace Fuse.Triggers.Actions
{
	public interface IToggleable
	{
		void Toggle();
	}

	/** Toggles the state of a toggleable component.
	
	    It is not recommended to use this trigger action to toggle a logical state in your app. For that, use
	    an Observable boolean in JavaScript and manipulate its value in a callback.

		## Example

			<StackPanel>
				<Switch ux:Name="switch1" />
	
				<Button Text="Toggle!">
					<Clicked>
						<Toggle Target="switch1" />
					</Clicked>
				</Button>
			</StackPanel>


	*/
	public class Toggle : TriggerAction
	{
		/** The ToggleControl (or Switch) to toggle. 
			If not specified this Action will look up the tree for the next control. 
		*/
		public IToggleable Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target ?? target.FindByType<IToggleable>();
			if (t == null)
			{
				Fuse.Diagnostics.UserError( "Could not find `IToggleable` target", this );
				return;
			}
			
			t.Toggle();
		}
	}
}