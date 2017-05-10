using Uno;
using Uno.Testing;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Input;
using FuseTest;

namespace Fuse.Test
{
	class PointerElement: Panel
	{
		private bool _pressed = false;
		private bool _captured = false;
		private bool _entered = false;

		public bool Pressed 
		{
			get { return _pressed; }
		}

		public bool Captured 
		{
			get { return _captured; }
		}

		public bool Entered 
		{
			get { return _entered; }
		}

		public bool HardCaptureModeEnabled { get; set; }

		public bool SoftCaptureModeEnabled { get; set; }

		public PointerElement(string name, bool softCaptureModeEnabled = false, bool hardCaptureModeEnabled = false)
		{
			Name = name;
			SoftCaptureModeEnabled = softCaptureModeEnabled;
			HardCaptureModeEnabled = hardCaptureModeEnabled;
			HitTestMode = HitTestMode.LocalBounds | HitTestMode.Children;

			Fuse.Input.Pointer.Pressed.AddHandler(this, OnPointerPressed);
			Fuse.Input.Pointer.Released.AddHandler(this, OnPointerReleased);
			Fuse.Input.Pointer.Moved.AddHandler(this, OnPointerMoved);
			Fuse.Input.Pointer.Entered.AddHandler(this, OnPointerEntered);
			Fuse.Input.Pointer.Left.AddHandler(this, OnPointerLeft);
		}

		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			_pressed = true;
			if (_captured)
				return;
				
			if (SoftCaptureModeEnabled && args.TrySoftCapture(this, OnCaptureLost))
			{
				_captured = true;
			}
		}

		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			if (_captured)
			{
				if (HardCaptureModeEnabled && !args.IsHardCapturedTo(this))
				{
					args.TryHardCapture(this, OnCaptureLost);
				}
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			_pressed = false;
			ReleaseCapture();
		}

		void OnPointerEntered(object sender, PointerEnteredArgs args)
		{
			_entered = true;
		}

		void OnPointerLeft(object sender, PointerLeftArgs args)
		{
			_entered = false;
		}

		void ReleaseCapture()
		{
			if (!_captured)
				return;
				
			Fuse.Input.Pointer.ReleaseCapture(this);
			OnCaptureLost();
		}

		void OnCaptureLost()
		{
			_captured = false;
		}
	}
}
