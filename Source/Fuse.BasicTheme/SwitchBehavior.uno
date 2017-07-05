using Uno;
using Uno.UX;
using Fuse.Input;
using Fuse.Gestures;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Scripting;

namespace Fuse.BasicTheme
{
	class SwitchBehavior : Trigger
	{
		ToggleControl _switch;

		Element _bounds;
		public Element Bounds
		{
			get { return _bounds; }
			set { _bounds = value; }
		}

		Clicker _clicker;
		protected override void OnRooted()
		{
			base.OnRooted();

			_switch = Parent as ToggleControl;
			if (_switch == null)
				throw new Exception("SwitchBehavior must be rooted in a Switch");
			_switch.ValueChanged += OnValueChanged;

			Pointer.Pressed.AddHandler(_switch, OnPointerPressed);
			Pointer.Moved.AddHandler(_switch, OnPointerMoved);
			Pointer.Released.AddHandler(_switch, OnPointerReleased);

			_clicker = Clicker.AttachClicker(_switch, GesturePriority.Normal);
			_clicker.TappedEvent += OnPointerTapped;

			if (Bounds == null)
				Bounds = _switch as Element;

			if (_switch.Value)
				Activate();
		}

		protected override void OnUnrooted()
		{
			_switch.ValueChanged -= OnValueChanged;

			Pointer.Pressed.RemoveHandler(_switch, OnPointerPressed);
			Pointer.Moved.RemoveHandler(_switch, OnPointerMoved);
			Pointer.Released.RemoveHandler(_switch, OnPointerReleased);

			_switch.Placed -= OnPlaced;
			_clicker.TappedEvent -= OnPointerTapped;
			_clicker.Detach();
			_clicker = null;
			_switch = null;
			Bounds = null;

			Pointer.ReleaseCapture(this);
			base.OnUnrooted();
		}

		float2 _prevCoord;
		float2 _currentCoord;

		float2 Size
		{
			get { return _bounds.ActualSize; }
		}


		float2 _originalP;

		void OnPlaced(object sender, PlacedArgs args)
		{
			//TODO: I don't like that this needs to be done. likely only because the style has
			//a Move animator relative ot the node size (perhaps it should listen instead)
			PlayEnd(_switch.Value);
		}

		bool _captured;
		int _capturedIndex;
		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			if (_captured)
				return;

			if (args.TrySoftCapture(this, OnCaptureLost))
			{
				_captured = true;
				_capturedIndex = args.PointIndex;
				_originalP = _prevCoord = _currentCoord = _switch.WindowToLocal(args.WindowPoint);
			}
		}

		void OnCaptureLost()
		{
			_captured = false;
			PlayEnd(_switch.Value);
		}

		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			if (_captured)
			{
				if (!args.IsHardCapturedTo(this))
				{
					if (Math.Abs(_originalP.X - _switch.WindowToLocal(args.WindowPoint).X ) > 10)
					{
						if (!args.TryHardCapture(this, OnCaptureLost))
						{
							OnCaptureLost();
							return;
						}
					}
				}

				_prevCoord = _currentCoord;
				_currentCoord = _switch.WindowToLocal(args.WindowPoint);
				var delta = _currentCoord - _prevCoord;

				var p = (delta.X / Size.X);
				Seek( Progress + p, (_switch.Value) ? AnimationVariant.Backward
						: AnimationVariant.Forward );
			}
		}

		bool ReleaseCapture()
		{
			if (!_captured)
				return false;

			Pointer.ReleaseCapture(this);
			_captured = false;
			return true;
		}

		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			if (ReleaseCapture())
			{
				_switch.Value = Progress >= 0.5;
				PlayEnd(_switch.Value);
			}
		}

		void OnPointerTapped(object a, int tapCount)
		{
			ReleaseCapture();
			_switch.Value = !_switch.Value;
			PlayEnd(_switch.Value);
		}

		void OnValueChanged(object sender, ValueChangedArgs<bool> args)
		{
			PlayEnd(args.Value);
		}
	}
}
