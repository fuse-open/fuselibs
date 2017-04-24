using Fuse.Input;

namespace Fuse.Gestures
{
	/** Triggers when a pointer is released on a @Visual.

		As opposed to @Clicked or @Tapped, this trigger triggers without concern for how long the pointer was pressed for.

		# Example
		In this example, a panel will rotate for 0.4 seconds, then rotate back, when released:

			<Panel Background="#F00">
				<Released>
					<Rotate Degrees="90" Duration=".4" DurationBack=".2" />
				</Released>
			</Panel>
	*/
	public class Released : Fuse.Triggers.Trigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Pointer.Released.AddHandler(Parent, OnReleased);
		}

		protected override void OnUnrooted()
		{
			Pointer.Released.RemoveHandler(Parent, OnReleased);
			base.OnUnrooted();
		}

		void OnReleased(object s, object a)
		{
			Pulse();
		}
	}
}
