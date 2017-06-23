using Uno;
using Uno.UX;

using Fuse.Input;

namespace Fuse.Gestures
{
	public enum PointerCaptureOn
	{
		/** Enabled of the capture will be done manually by setting `IsActive` */
		None,
		Pressed,
	}

	/**
		Locks pointer input to a sub-tress in the UX for a limited time.
		
		@experimental It's unsure if the default properties/behaviour make sense. We'll have to complete more combined gestures first.
	*/
	public class PointerCapture : Behavior, IGesture, IPropertyListener
	{
		PointerCaptureOn _on = PointerCaptureOn.None;
		public PointerCaptureOn On
		{
			get { return _on; }
			set
			{
				if ( value == _on)
					return;
					
				_on = value;
			}
		}
		
		static Selector IsActiveName = "IsActive";
		bool _isActive;
		[UXOriginSetter("SetIsActive")]
		public bool IsActive
		{	
			get { return _isActive; }
			set { SetIsActive(value, this); }
		}
		
		public void SetIsActive(bool value, IPropertyListener origin)
		{
			if (value == _isActive)
				return;
				
			_isActive = value;
			OnPropertyChanged(IsActiveName, origin);
			
			if (_gesture != null && origin != _gesture && !_isActive)
				_gesture.Dispose();
		}
		
		Gesture _gesture;
		protected override void OnRooted()
		{
			base.OnRooted();
			
			if (On == PointerCaptureOn.Pressed)
				_gesture = Input.Gestures.Add( this, Parent, GestureType.Primary | GestureType.Children);
		}
		
		protected override void OnUnrooted()
		{
			if (_gesture != null)
			{
				_gesture.Dispose();
				_gesture = null;
			}
			
			base.OnUnrooted();
		}
		
		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				return new GesturePriorityConfig(GesturePriority.Normal);
			}
		}
		
		GestureRequest IGesture.OnPointerPressed( PointerPressedArgs args )
		{
			return GestureRequest.Capture;
		}
		
		GestureRequest IGesture.OnPointerMoved( PointerMovedArgs args )
		{
			return GestureRequest.Capture;
		}
		
		GestureRequest IGesture.OnPointerReleased( PointerReleasedArgs args )
		{
			return GestureRequest.Cancel;
		}
		
		void IGesture.OnCaptureChanged( PointerEventArgs args, CaptureType how, CaptureType prev )
		{
			SetIsActive(true, _gesture);
		}
		
		void IGesture.OnLostCapture( bool forced )
		{
			SetIsActive(false, _gesture);
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector value) {}
	}
}
