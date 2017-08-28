using Uno;
using Uno.UX;
using Fuse.Input;

namespace Fuse
{
	public abstract partial class Visual
	{
		static PropertyHandle _isContextEnabledChangedHandle = Fuse.Properties.CreateHandle();

		/** Raised when the IsContextEnabled property changes 
			@advanced */
		public event EventHandler IsContextEnabledChanged
		{
			add { AddEventHandler(_isContextEnabledChangedHandle, VisualBits.IsContextEnabledChanged, value); }
			remove { RemoveEventHandler(_isContextEnabledChangedHandle, VisualBits.IsContextEnabledChanged, value); }
		}

		static readonly Selector _isEnabledName = "IsEnabled";
		/** Whether this node is currently interactable.
			Disabled visuals do not receive input focus. However, they can still
			be visible and block hit test for underlaying objects. 

			You can use the @WhileEnabled and @WhileDisabled triggers to specify different styling for
			a visual while enabled/disabled.

			@see IsContextEnabled
		*/
		public bool IsEnabled
		{
			get { return HasBit(FastProperty1.IsEnabled); }
			set 
			{ 
				if (value != IsEnabled)
				{
					SetBit(FastProperty1.IsEnabled, value);
					UpdateIsContextEnabledCache();
					OnIsEnabledChanged(this);
				}
			}
		}

		void OnIsEnabledChanged(IPropertyListener origin)
		{
			OnPropertyChanged(_isEnabledName, origin);
		}
		
		/** Whether this node is in an enabled context.
			The context is disabled if one of the ancestor nodes have @IsEnabled set to `false`.

			You can use the @WhileContextEnabled and @WhileContextDisabled triggers to specify different 
			styling for	a visual while the context is enabled or disabled.

			@see IsEnabled
		*/
		public bool IsContextEnabled
		{
			get { return HasBit(FastProperty1.IsContextEnabledCache); }
		}

		void UpdateIsContextEnabledCache()
		{
			var newValue = IsEnabled && (Parent == null || Parent.IsContextEnabled);

			if (IsContextEnabled != newValue)
			{
				SetBit(FastProperty1.IsContextEnabledCache, newValue);
				OnIsContextEnabledChanged();

				for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
					v.UpdateIsContextEnabledCache();
			}
		}
		
		protected virtual void OnIsContextEnabledChanged()
		{
			RaiseEvent(_isContextEnabledChangedHandle, VisualBits.IsContextEnabledChanged);
			InvalidateHitTestBounds();
			InvalidateVisual();
		}
	}
}