using Uno;

using Fuse.Triggers;
using Fuse.Scripting;

namespace Fuse.Selection
{
	public class SelectionEventArgs : EventArgs, IScriptEvent
	{
		/**
			The `Value` of the @Selectable
		*/
		public string Value { get; private set; }
		
		public SelectionEventArgs(string value)
		{
			this.Value = value;
		}
		
		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString( "value", Value );
		}
	}
	
	abstract public class SelectionEvent : PulseTrigger<SelectionEventArgs>
	{
		internal SelectionEvent() { }
		
		Selectable _selectable;
		Selection _selection;

		bool _selected;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			if (!Selection.TryFindSelectable(Parent, out _selectable, out _selection))
			{
				Fuse.Diagnostics.UserError( "Unable to locate a `Selectable` and `Selection`", this );
				return;
			}
			
			_selection.SelectionChanged += OnSelectionChanged;
			_selected = _selection.IsSelected(_selectable);
		}
		
		protected override void OnUnrooted()
		{
			if (_selection != null)
				_selection.SelectionChanged -= OnSelectionChanged;
			
			_selection = null;
			_selectable = null;
			base.OnUnrooted();
		}
		
		void OnSelectionChanged(object s, object args)
		{
			var news = _selection.IsSelected(_selectable);
			if (news == _selected)
				return;

			if (IsTriggered(news))
				Pulse(new SelectionEventArgs(_selectable.Value));
			_selected = news;
		}
		
		protected abstract bool IsTriggered(bool on);
	}

	/**
		Fired when the @Selectable is assed to the @Selection.
	*/
	public class Selected : SelectionEvent
	{
		protected override bool IsTriggered(bool on)
		{
			return on;
		}
	}
	
	/**
		Fired when the @Selectable is removed from the @Selection.
	*/
	public class Deselected : SelectionEvent
	{
		protected override bool IsTriggered(bool on)
		{
			return !on;
		}
	}
}