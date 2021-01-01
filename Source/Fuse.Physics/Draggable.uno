using Uno;
using Uno.UX;
using Fuse.Elements;
using Fuse.Input;

namespace Fuse.Physics
{
	public enum Axis2D
	{
		XY,
		X,
		Y
	}

	/**
		@mount Physics
	*/
	public class Draggable : Behavior, IRule, IGesture
	{
		Body _body;
		Gesture _gesture;

		float2 _translation;

		/** To track translation information when user drag the @Visual */
		[UXOriginSetter("SetTranslation")]
		public float2 Translation
		{
			get { return _translation; }
			set { SetTranslation(value, null); }
		}

		static Selector _translationName = "Translation";
		public void SetTranslation(float2 value, IPropertyListener origin)
		{
			if (_translation != value)
			{
				_translation = value;
				OnPropertyChanged(_translationName);
			}
		}

		public Element Bounds { get; set; }

		/**
			Sets the draggable behavior to be locked to a single axis.
			Can be set to X, Y or XY (the default, unconstrained)
		*/
		public Axis2D Axis { get; set; }

		protected override void OnRooted()
		{
			base.OnRooted();
			_body = Body.Pin(Parent);
			_body.World.AddRule(this);

			_gesture = Input.Gestures.Add( this, Parent, GestureType.Multi);
		}

		protected override void OnUnrooted()
		{
			_body.World.RemoveRule(this);
			_body.Unpin();
			_body = null;
			_point = null;

			_gesture.Dispose();
			_gesture = null;
			base.OnUnrooted();
		}

		float3 GetPointerPosition(Fuse.Input.PointerEventArgs args)
		{
			// TODO: transform into local space
			return float3(args.WindowPoint, 0);
		}

		bool _hasLock;

		class Point {
			public int Down = -1;
			public float3 Start, Current, Previous;
		}

		Point _point = new Point();

		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				float sig = _point.Down == -1 ? 0f : Vector.Length( _point.Current - _point.Start );

				return new GesturePriorityConfig( GesturePriority.Low, sig );
			}
		}

		void IGesture.OnLostCapture(bool forced)
		{
			_point.Down = -1;
			if (_hasLock)
			{
				_hasLock = false;
				_body.UnlockMotion();
				WhileDragging.End(_body.Visual);
			}
		}


		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs args)
		{
			if (_point.Down > -1) {
				return GestureRequest.Cancel;
			}

			_point.Down = args.PointIndex;
			_point.Current = _point.Start = _point.Previous = GetPointerPosition(args);

			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs args)
		{
			if (_hasLock)
			{
				_hasLock = false;
				_body.UnlockMotion();
				WhileDragging.End(_body.Visual);
				_body.ReleasePointer();
			}

			return GestureRequest.Cancel;
		}

		void IGesture.OnCaptureChanged(PointerEventArgs args, CaptureType type, CaptureType prev )
		{
			if (CaptureTypeHelper.BecameHard(prev, type))
			{
				_hasLock = _body.TryLockMotion(this);

				if (!_hasLock) return;

				_point.Down = args.PointIndex;
				_point.Current = _point.Start = _point.Previous = GetPointerPosition(args);

				_body.SetPointerPosition(_point.Current);

				WhileDragging.Begin(_body.Visual);
			}
		}


		float3 _forceMotion;

		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs args)
		{
			_point.Current = GetPointerPosition(args);

			if (_hasLock) {
				var delta =  _point.Current - _point.Previous;
				_point.Previous = _point.Current;

				switch(Axis)
				{
					case Axis2D.X:
						delta.Y = 0;
						break;
					case Axis2D.Y:
						delta.X = 0;
						break;
				}

				_forceMotion += delta;
			}

			return GestureRequest.Capture;
		}

		void IRule.Update(double deltaTime, World world)
		{
			_body.Move(_forceMotion);
			_body.ApplyForce(_forceMotion*0.3f / (float)deltaTime);
			_body.ConstrainToBounds(Bounds);

			_forceMotion = float3(0);
		}

	}

	/**
		Active while the element is being dragged.

		@examples Docs/WhileDragging.md
	*/
	public class WhileDragging : Fuse.Triggers.Trigger
	{
		internal static void Begin(Visual n)
		{
			for (var v = n.FirstChild<WhileDragging>(); v != null; v = v.NextSibling<WhileDragging>())
				v.Activate();
		}

		internal static void End(Visual n)
		{
			for (var v = n.FirstChild<WhileDragging>(); v != null; v = v.NextSibling<WhileDragging>())
				v.Deactivate();
		}
	}
}