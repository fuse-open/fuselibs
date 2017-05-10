using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;
using Fuse.Input;
using Fuse.Triggers;


namespace Fuse.Gestures
{
	/**
		Active while a pointer is within the bounds of its containing element.

		Note that this trigger only has a value when the device
		supports a hovering pointer such as the mouse pointer on
		desktop machines. This trigger is thus not useful on most
		smart phones.

		## Example

		This example demonstrates how to scale `Panel` by a factor of 2 when a pointer hovers over it:

			<Panel Width="50" Height="50">
				<WhileHovering>
					<Scale Factor="2" Duration="0.2" />
				</WhileHovering>
			</Panel>
	*/
	public class WhileHovering: Trigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Pointer.Entered.AddHandler(Parent, OnPointerEntered);
			Pointer.Left.AddHandler(Parent, OnPointerLeft);
			Parent.IsContextEnabledChanged += OnIsContextEnabledChanged;
		}

		protected override void OnUnrooted()
		{
			Pointer.Entered.RemoveHandler(Parent, OnPointerEntered);
			Pointer.Left.RemoveHandler(Parent, OnPointerLeft);
			Parent.IsContextEnabledChanged -= OnIsContextEnabledChanged;
			base.OnUnrooted();
		}

		void OnPointerEntered(object sender, object args)
		{
			Activate();
		}

		void OnPointerLeft(object sender, object args)
		{
			Deactivate();
		}

		//this removes the hovered effect without waiting for the next point event
		void OnIsContextEnabledChanged(object s, object a)
		{
			if (!Parent.IsContextEnabled)
				Deactivate();
		}
	}
}
