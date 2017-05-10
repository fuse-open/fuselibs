using Uno;
using Uno.Diagnostics;

using Fuse;
using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Input;
using Fuse.Motion.Simulation;

namespace Fuse.Navigation
{
	class UpdateSeekArgs
	{
		public float Delta { get; private set; }
		public float Distance { get; private set; }

		public float RelativeDelta
		{
			get { return Delta / _scale; }
		}

		public float RelativeDistance
		{
			get { return Distance / _scale; }
		}

		float _scale;
		double _time;

		public UpdateSeekArgs(
			float delta,
			float distance,
			float scale,
			double time)
		{
			Delta = delta;
			Distance = distance;
			_scale = scale;
			_time = time;
		}
	}

	enum SnapTo
	{
		Forward,
		Current,
		Backward
	}

	class EndSeekArgs
	{
		public float Velocity { get; private set; }
		public SnapTo SnapTo { get; private set; }

		public EndSeekArgs(SnapTo snapTo, float velocity = 0)
		{
			SnapTo = snapTo;
			Velocity = velocity;
		}
	}

	/**
		The direction of a swipe gesture. `Left` means swiping to the left, etc.
	*/
	public enum SwipeDirection
	{
		Right,
		Left,
		Down,
		Up,
	}

	/**
		Which direction of navigation is allowed.
	*/
	public enum AllowedNavigationDirections
	{
		/** Only forward navigation is allowed. */
		Forward = 1 << 0,
		/** Only backward navigation is allowed. */
		Backward = 1 << 1,
		/** Forward and backward navigation are allowed */
		Both = Forward | Backward,
	}

	/**
		@mount Navigation
	*/
	public class SwipeNavigate : Behavior
	{
		ISeekableNavigation Navigation
		{
			get 
			{ 
				return Fuse.Navigation.Navigation.TryFindBaseNavigation(ContextParent) as ISeekableNavigation; 
			}
		}

		PointerVelocity<float2> _velocity = new PointerVelocity<float2>();
			
		ISeekableNavigation _currentNavigation = null;
		protected override void OnRooted()
		{
			base.OnRooted();

			Pointer.Pressed.AddHandler(Parent, OnPointerPressed);
			Pointer.Moved.AddHandler(Parent, OnPointerMoved);
			Pointer.Released.AddHandler(Parent, OnPointerReleased);
		}

		protected override void OnUnrooted()
		{
			Pointer.Pressed.RemoveHandler(Parent, OnPointerPressed);
			Pointer.Moved.RemoveHandler(Parent, OnPointerMoved);
			Pointer.Released.RemoveHandler(Parent, OnPointerReleased);

			base.OnUnrooted();
		}

		SwipeDirection _forwardDirection = SwipeDirection.Left;
		/**
			Specifies the direction the user should swipe to move forward in the navigation. Forward
			means towards the "entering" pages (those in front).
		*/
		public SwipeDirection ForwardDirection 
		{ 
			get { return _forwardDirection; }
			set { _forwardDirection = value; }
		}
		
		/**
			DEPRECATED: use ForwardDirection, Note the old direction had the unfortunate aspect of being
			the `BackwardDirection`: so you must specify the opposite direction.
		*/
		public SwipeDirection SwipeDirection 
		{ 
			get { return Invert(ForwardDirection); }
			set { ForwardDirection = Invert(value); }
		}
		
		SwipeDirection Invert(SwipeDirection sd)
		{
			switch(sd)
			{
				case SwipeDirection.Left: return SwipeDirection.Right;
				case SwipeDirection.Right: return SwipeDirection.Left;
				case SwipeDirection.Up: return SwipeDirection.Down;
				case SwipeDirection.Down: return SwipeDirection.Up;
			}
			return SwipeDirection.Left;
		}
		
		public float VelocityThreshold { get; set; }

		Element _lengthNode;
		/**
			Specifies a node to use to determine the size of the page for a swipe. If not specified the
			navigation's parent control will be used. This is sometimes useful in complex layouts where
			the navigation control doesn't reflect the true size of the pages being swiped.
		*/
		public Element LengthNode
		{
			get { return _lengthNode; }
			set { _lengthNode = value; }
		}
		
		bool _hasMaxPages;
		float _maxPages;
		/**
			Specifies the maximum number of pages that can be swiped at one-time. This is useful
			when the pages are not the full-screen, but overlap, and the user would otherwise be
			able to swipe more than one page at a time.
		*/
		public float MaxPages
		{
			get { return _maxPages; }
			set
			{
				_hasMaxPages = true;
				_maxPages = value;
			}
		}

		bool IsHorizontal { get { return ForwardDirection == SwipeDirection.Left ||
			ForwardDirection == SwipeDirection.Right; } }
		bool IsVertical { get { return ForwardDirection == SwipeDirection.Up ||
			ForwardDirection == SwipeDirection.Down; } }

		float2 _startCoord;
		float2 _currentCoord;
		float _prevDistance;
		double _startTime = 0.0;

		const float _delayStartThresholdDistance = 10;
		static internal float TestDelayStartThresholdDistance { get { return _delayStartThresholdDistance; } }
		
		SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(_delayStartThresholdDistance,
			new DegreeSpan( 75.0f,  105.0f),
			new DegreeSpan(-75.0f, -105.0f));

		SwipeGestureHelper _verticalGesture = new SwipeGestureHelper(_delayStartThresholdDistance,
			new DegreeSpan(-15.0f,    15.0f),
			new DegreeSpan(-165.0f, -180.0f),
			new DegreeSpan( 165.0f,  180.0f));

		public SwipeNavigate()
		{
			VelocityThreshold = 300f; //matched to Swiper
		}

		int _down = -1;

		void OnLostCapture()
		{
			_down = -1;
			if (_currentNavigation != null)
			{
				if ( (_currentNavigation as Node).IsRootingCompleted)
					_currentNavigation.EndSeek(new EndSeekArgs(SnapTo.Current));

				_currentNavigation = null;
			}
		}

		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			_currentNavigation = Navigation;
			if (_currentNavigation == null)
			{
				debug_log "SwipeNavigate: failed to find suitable Navigation object";
				return;
			}

			if (args.TrySoftCapture(this, OnLostCapture))
			{
				_down = args.PointIndex;
				_startCoord = _currentCoord = args.WindowPoint;
				_prevDistance = 0;
				_startTime = Time.FrameTime;
				_velocity.Reset( _startCoord, float2(0), args.Timestamp );
			}
		}

		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			if (_down != args.PointIndex)
				return;

			if (_currentNavigation == null)
				return;

			_currentCoord = args.WindowPoint;
			_velocity.AddSampleTime( _currentCoord, args.Timestamp,
				args.IsHardCapturedTo(this) ? SampleFlags.None : SampleFlags.Tentative );

			if (args.IsHardCapturedTo(this))
			{
				_currentNavigation.Seek(GetNavigationArgs());
			}
			else
			{
				var diff = _currentCoord - _startCoord;
				var withinBounds = IsHorizontal
					? _horizontalGesture.IsWithinBounds(diff)
					: _verticalGesture.IsWithinBounds(diff);

				if (withinBounds)
				{
					//reset coords to avoid jump (https://github.com/fusetools/fuselibs/issues/1175)
					_startCoord = _currentCoord = args.WindowPoint;
					_prevDistance = 0;
					_startTime = Time.FrameTime;
					
					if (args.TryHardCapture(this, OnLostCapture))
						_currentNavigation.BeginSeek();
					else
						OnLostCapture();
				}
			}
		}

		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			_currentCoord = args.WindowPoint;
			_velocity.AddSampleTime( _currentCoord, args.Timestamp, SampleFlags.Release );
			_down = -1;

			if (_currentNavigation == null)
				return;

			if (args.IsHardCapturedTo(this))
			{
				_currentNavigation.EndSeek(
					new EndSeekArgs(DetermineSnap(), ProgressVelocity) );
			}
			args.ReleaseCapture(this);
			_currentNavigation = null;
		}

		float2 Scale
		{
			get 
			{ 
				if (_lengthNode != null)
					return _lengthNode.ActualSize;
				var e = Parent as Element;
				if (e == null)
					return float2(1);
				return e.ActualSize; 
			}
		}

		float2 Distance
		{
			get { return _currentCoord - _startCoord; }
		}

		double ElapsedTime
		{
			get { return Time.FrameTime - _startTime; }
		}

		float ProgressVelocity
		{
			get
			{
				switch (SwipeDirection)
				{
					case SwipeDirection.Left: return -_velocity.CurrentVelocity.X / Scale.X;
					case SwipeDirection.Right: return _velocity.CurrentVelocity.X / Scale.X;
					case SwipeDirection.Up: return -_velocity.CurrentVelocity.Y / Scale.Y;
					case SwipeDirection.Down: return _velocity.CurrentVelocity.Y / Scale.Y;
				}
				return 0;
			}
		}

		AllowedNavigationDirections _swipeAllow = AllowedNavigationDirections.Both;
		/**
			Indicates which directions of swiping are allowed by this gesture. This affects only
			the user control of this gesture; the underlying navigation can still be programatically
			navigated in any direction.
		*/
		public AllowedNavigationDirections AllowedDirections
		{
			get { return _swipeAllow; }
			set { _swipeAllow = value; }
		}
		
		UpdateSeekArgs GetNavigationArgs()
		{
			float distance, scale;

			if (IsHorizontal)
			{
				distance = Distance.X;
				scale = Scale.X;
			}
			else
			{
				distance = Distance.Y;
				scale = Scale.Y;
			}

			if (ForwardDirection == SwipeDirection.Right || ForwardDirection == SwipeDirection.Down)
				distance = -distance;

			var rel = distance / scale;
			
			if (!AllowedDirections.HasFlag(AllowedNavigationDirections.Backward))
				rel = Math.Min(0,rel);
			if (!AllowedDirections.HasFlag(AllowedNavigationDirections.Forward))
				rel = Math.Max(0,rel);
			if (_hasMaxPages)
				rel = Math.Clamp(rel, -_maxPages, _maxPages);
				
			var clampDistance = rel * scale;
			var delta = clampDistance - _prevDistance;
			_prevDistance = clampDistance;

			return new UpdateSeekArgs(delta, clampDistance, scale, ElapsedTime);
		}

		//similar as from ScrollViewBehaviour (different decay)
		//for providing a rubber-band feel to limited ends
		static readonly float elasticDecay = 0.015f;
		static readonly float elasticScale = 0.4f;
		float ElasticDistance( float v )
		{
			bool neg = false;
			if (v < 0)
			{
				v = -v;
				neg = true;
			}

			//the intergral of an expontential decay
			v = (Math.Pow( elasticDecay, v * elasticScale ) -1) / Math.Log(elasticDecay);

			if (neg)
				v = -v;

			return v;
		}

		SnapTo DetermineSnap()
		{
			float diff = IsHorizontal ? _velocity.CurrentVelocity.X : _velocity.CurrentVelocity.Y;
			if (ForwardDirection == SwipeDirection.Right || ForwardDirection == SwipeDirection.Down)
				diff = -diff;

			var q = SnapTo.Current;
			if (diff < -VelocityThreshold && AllowedDirections.HasFlag(AllowedNavigationDirections.Forward))
				q = SnapTo.Forward;
			if (diff > VelocityThreshold && AllowedDirections.HasFlag(AllowedNavigationDirections.Backward))
				q = SnapTo.Backward;

			return q;
		}

	}
}
