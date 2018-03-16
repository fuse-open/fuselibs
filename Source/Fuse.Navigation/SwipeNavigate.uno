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
	public class SwipeNavigate : Behavior, IGesture
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
		Gesture _gesture;
		protected override void OnRooted()
		{
			base.OnRooted();

			_gesture = Input.Gestures.Add( this, Parent, GestureType.Primary );
		}

		protected override void OnUnrooted()
		{
			_gesture.Dispose();
			_gesture = null;
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

		float2 Direction
		{
			get { return IsHorizontal ? float2(1,0) : float2(0,1); }
		}

		float2 _startCoord;
		float2 _currentCoord;
		float _prevDistance;
		double _startTime = 0.0;

		public SwipeNavigate()
		{
			VelocityThreshold = 300f; //matched to Swiper
		}

		void IGesture.OnLostCapture(bool forced)
		{
			if (_currentNavigation != null)
			{
				if ( (_currentNavigation as Node).IsRootingCompleted && _startedSeek)
					_currentNavigation.EndSeek(new EndSeekArgs(SnapTo.Current));

				_currentNavigation = null;
			}
			_startedSeek = false;
		}

		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				var diff = _currentCoord - _startCoord;
				return new GesturePriorityConfig( GesturePriority.Low,
					Gesture.VectorSignificance( Direction, diff ) );
			}
		}
		
		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs args)
		{
			_startCoord = _currentCoord = args.WindowPoint;
			_currentNavigation = Navigation;
			_velocity.Reset( _startCoord, float2(0), args.Timestamp );
			if (_currentNavigation == null)
			{
				Fuse.Diagnostics.InternalError("SwipeNavigate: failed to find suitable Navigation object", this);
				return GestureRequest.Ignore;
			}
			return GestureRequest.Capture;
		}
		
		bool _startedSeek;
		void IGesture.OnCaptureChanged(PointerEventArgs args, CaptureType how, CaptureType prev)
		{
			//always reset coords to avoid jump (https://github.com/fusetools/fuselibs-private/issues/1175)
			_startCoord = _currentCoord = args.WindowPoint;
			_prevDistance = 0;
			_startTime = Time.FrameTime;

			if (how.HasFlag(CaptureType.Hard) && !prev.HasFlag(CaptureType.Hard))
			{
				_currentNavigation.BeginSeek();
				_startedSeek = true;
			}
		}

		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs args)
		{
			if (_currentNavigation == null)
				return GestureRequest.Cancel;

			_currentCoord = args.WindowPoint;
			_velocity.AddSampleTime( _currentCoord, args.Timestamp,
				_gesture.IsHardCapture ? SampleFlags.None : SampleFlags.Tentative );

			if (_gesture.IsHardCapture)
				_currentNavigation.Seek(GetNavigationArgs());
			
			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs args)
		{
			_currentCoord = args.WindowPoint;
			_velocity.AddSampleTime( _currentCoord, args.Timestamp, SampleFlags.Release );

			if (_gesture.IsHardCapture && _currentNavigation != null)
			{
				_currentNavigation.EndSeek(
					new EndSeekArgs(DetermineSnap(), ProgressVelocity) );
				//clear now to prevent double EndSeek in OnLostCapture
				_currentNavigation = null;
			}
			return GestureRequest.Cancel;
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
