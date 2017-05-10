

namespace Fuse.Triggers.Actions
{
	public interface IToggleable
	{
		void Toggle();
	}

	/** Toggles the state of a toggleable component.
	
	    It is not reccommended to use this trigger action to toggle a logical state in your app. For that, use
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
		public IToggleable Target { get; set; }
		
		protected override void Perform(Node target)
		{
			var t = Target ?? FindTarget(target);
			if (t != null) t.Toggle();
		}

		IToggleable FindTarget(Node n)
		{
			while (n != null)
			{
				var iv = n as IToggleable;
				if (iv != null) return iv;
				n = n.Parent;
			}
			return null;
		}
	}
}