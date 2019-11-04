using Uno;
using Uno.UX;

namespace Fuse.Selection
{
	/**
		`Selectable` makes a Visual selectable. Selectable visuals are what can be selected in  a @Selection control.
		
		The `Value` property is used by the @Selection to track what is selected. It is a string value to make it easy to work with from JavaScript.
		
		## Changing the selected state
		
		There is no default behavior that changes a visuals selected state. In order to select a @(Selectable:selectable), you need to use @(ToggleSelection). A normal use of this would be inside a @(Clicked) trigger, like this:
		
			<Panel>
				<Selection />
				<Panel>
					<Selectable />
					<Clicked>
						<ToggleSelection />
					</Clicked>
				</Panel>
			</Panel>
		
		## Reacting to a change in selected state
		
		You can react to changes in the state of a @(Selectable) element using @(Selected), which pulses when the element is selected, or @(WhileSelected), which is true as long as the element is selected.
		
		@examples Docs/example.md
	*/
	public partial class Selectable : Behavior
	{
		Selection _selection;
		
		protected override void OnRooted()
		{
			base.OnRooted();
			
			_selection = Selection.TryFindSelection(Parent);
			if (_selection == null)
				Fuse.Diagnostics.UserError( "Unable to locate `Selection`", this );
		}
		
		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			_selection = null;
		}
		
		internal static Selector ValueName = new Selector("Value");
		
		string _value;
		/**
			The value which identifies this `Selectable` in the `Selection`. It will be this value that is used in `Selection.Value` and `Selection.Values`.
			
			A `Value` of a `Selectable` that is currently selected can be modified, in which case the selected value will also be modified.
		*/
		public String Value
		{
			get { return _value; }
			set
			{
				if (_value == value)
					return;

				var old = _value;
				_value = value;
				
				if (_selection != null)	
					_selection.ModifyValue(old, _value);
				OnPropertyChanged(ValueName);
			}
		}

		/**
			Calls `Selection.Add` with this `Selectable`.
		*/
		public void Add()
		{
			if (_selection == null)
			{
				Fuse.Diagnostics.UserError( "No selection, perhaps not rooted", this);
				return;
			}
			
			_selection.Add(this);
		}
		
		/**
			Calls `Selection.Remove` with this `Selectable`.
		*/
		public void Remove()
		{
			if (_selection == null)
			{
				Fuse.Diagnostics.UserError( "No selection, perhaps not rooted", this);
				return;
			}
			
			_selection.Remove(this);
		}
		
		/**
			Calls `Selection.Toggle` with this `Selectable`.
		*/
		public void Toggle()
		{
			if (_selection == null)
			{
				Fuse.Diagnostics.UserError( "No selection, perhaps not rooted", this);
				return;
			}
			
			_selection.Toggle(this);
		}
		
	}
}