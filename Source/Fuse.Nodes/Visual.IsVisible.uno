using Uno;
using Uno.UX;
using Fuse.Input;

namespace Fuse
{
	public abstract partial class Visual
	{
		static PropertyHandle _isVisibleChangedHandle = Fuse.Properties.CreateHandle();

		/** Raised when the `IsVisible` property changes.
			@advanced */
		public event EventHandler IsVisibleChanged
		{
			add { AddEventHandler(_isVisibleChangedHandle, VisualBits.IsVisibleChanged, value); }
			remove { RemoveEventHandler(_isVisibleChangedHandle, VisualBits.IsVisibleChanged, value); }
		}

		bool _isVisibleCached = true;
		/** Returns whether this visual is currently visible.
			Will return false if any of the ancestor visuals are hidden or collapsed.
			This property can *not* be used to check whether a visual is hidden because it is occluded by
			another visual, or is outside the view but otherwise visible. 
			@see fuse/visual/islocalvisible
		*/
		public bool IsVisible { get { return _isVisibleCached; } } 
		

		/** Returns whether this visual is visible without concern for whether an ancestor visual is hidden or collapsed.
			@see fuse/visual/isvisible
		*/
		public virtual bool IsLocalVisible { get { return true; } }
		
		//must be called by derived class whenever IsLocalVisible changes
		protected void OnLocalVisibleChanged()
		{
			UpdateIsVisibleCache();
		}
		
		void UpdateIsVisibleCache()
		{
			var newValue = IsLocalVisible && (Parent == null || Parent.IsVisible);
			
			if (_isVisibleCached != newValue)
			{
				_isVisibleCached = newValue;
				OnIsVisibleChanged();
				
				for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
					v.UpdateIsVisibleCache();
			}
		}
		
		protected virtual void OnIsVisibleChanged()
		{
			if (IsVisible)
				InvalidateVisual();
			if (Parent != null)
				Parent.InvalidateVisual();
			
			RaiseEvent(_isVisibleChangedHandle, VisualBits.IsVisibleChanged);
			InvalidateHitTestBounds();
		}
	}
}