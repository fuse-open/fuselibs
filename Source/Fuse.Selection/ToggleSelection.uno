using Uno;
using Uno.UX;

using Fuse.Triggers.Actions;

namespace Fuse.Selection
{
	public enum SelectMode
	{
		/** Toggles the selection on/off */
		Toggle,
		/** Adds the selectable to the selection */
		AddOnly,
		/** Removes the selectable from the selection */
		RemoveOnly,
	}

	[UXMissingPropertyHint("Data", "Perhaps you mean to use the `With` trigger, which used to be called `Select`.")]
	/**
		Modifies the selection state of a selectable in a selection.

		This looks for an ancestor node that is @Selectable.

		This obeys the user-interaction constraints of the @Selection. For example, it will not exceed `MaxCount`, nor go under `MinCount`. It is meant to create the high-level user interaction in a selection control.
	*/
	public class ToggleSelection : TriggerAction
	{
		SelectMode _mode = SelectMode.Toggle;
		/**
			How the item should be selected.

			The default is `Toggle`.
		*/
		public SelectMode Mode
		{
			get { return _mode; }
			set { _mode = value; }
		}

		protected override void Perform(Node target)
		{
			Selectable selectable;
			Selection selection;
			if (!Selection.TryFindSelectable(target, out selectable, out selection))
			{
				Fuse.Diagnostics.UserError( "Unable to locate Selectable", this);
				return;
			}

			switch (Mode)
			{
				case SelectMode.Toggle:
					selection.Toggle(selectable);
					break;

				case SelectMode.AddOnly:
					selection.Add(selectable);
					break;

				case SelectMode.RemoveOnly:
					selection.Remove(selectable);
					break;
			}
		}
	}
}