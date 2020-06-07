using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Selection
{
	/**
		This trigger is active while the @Selectable is currently selected in the @Selection

		This attaches to the first @Selectable node that is an ancestor of this one.

		Consider also the `isSelected()` function for use in expressions.

		@examples Docs/example.md
	*/
	public class WhileSelected : WhileTrigger, IPropertyListener
	{
		Selectable _selectable;
		Fuse.Selection.Selection _selection;

		protected override void OnRooted()
		{
			base.OnRooted();

			if (!Selection.TryFindSelectable(Parent, out _selectable, out _selection))
			{
				Fuse.Diagnostics.UserError( "Unable to locate a `Selectable` and `Selection`", this );
				return;
			}

			SetActive(_selection.IsSelected(_selectable));
			_selection.SelectionChanged += OnSelectionChanged;
			_selectable.AddPropertyListener(this);
		}

		protected override void OnUnrooted()
		{
			if (_selection != null)
			{
				_selection.SelectionChanged -= OnSelectionChanged;
				_selectable.RemovePropertyListener(this);
			}

			_selection = null;
			_selectable = null;
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == _selectable)
			{
				//assume a name change is config setup and should be done with bypass (ex. in a binding)
				BypassSetActive(_selection.IsSelected(_selectable));
			}
		}


		void OnSelectionChanged(object s, object args)
		{
			SetActive(_selection.IsSelected(_selectable));
		}
	}

}
