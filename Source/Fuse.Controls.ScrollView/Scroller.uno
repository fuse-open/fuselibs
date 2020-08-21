using Uno;
using Uno.UX;
using Uno.Diagnostics;

using Fuse.Controls;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Motion;
using Fuse.Motion.Simulation;

namespace Fuse.Gestures
{
	/**
		Implements the default scrolling functionality.

		There should be no reason to instantiate/reference this class directly. It will most likely be made internal an inaccessible in a future release.

		@advanced
		@deprecated 2017-03-04
	*/
	public class Scroller : Behavior, IPropertyListener, IGesture
	{
		//to avoid warning on deprecated public ctor
		internal Scroller(bool ignore) { }

		[Obsolete]
		public Scroller()
		{
			//DEPRECATED: 2017-03-04
			Fuse.Diagnostics.Deprecated( "Scroller should not be used directly as it is an internal class. The ScrollView provides the entire interface for scrolling.", this );
		}

		BoundedRegion2D _region;

		PointerVelocity<float2> _velocity = new PointerVelocity<float2>();

		const float hardCaptureVelocityThreshold = 100f;

		bool _delayStart = true;
		/**
			@deprecated 2017-03-04
		*/
		public bool DelayStart
		{
			get { return _delayStart; }
			set
			{
				_delayStart = value;
				Fuse.Diagnostics.Deprecated( "Scroller.DelayStart is no longer supported.", this );
			}
		}

		ScrollView _scrollable;

		protected override void OnRooted()
		{
			base.OnRooted();

			_scrollable = Parent as ScrollView;
			if (_scrollable == null)
				throw new Exception( "Scroller can only be used in a ScrollView" );

			_scrollable.AddPropertyListener(this);
			//Set in ugly fashion, required by https://github.com/fusetools/fuselibs-private/issues/870
			//previously the ScrollView would just listen for added children, but this appears safer
			_scrollable._scroller = this;
			_scrollable.RequestBringIntoView += OnRequestBringIntoView;
			_scrollable.ScrollPositionChanged += OnScrollPositionChanged;
			_region = _scrollable.Motion.AcquireSimulation();
			UpdatePointerEvents();
		}

		protected override void OnUnrooted()
		{
			StopInvalidateVisual();

			_scrollable.RemovePropertyListener(this);
			_scrollable.RequestBringIntoView -= OnRequestBringIntoView;
			_scrollable.ScrollPositionChanged -= OnScrollPositionChanged;
			_scrollable._scroller = null;

			if (_hasUpdated)
			{
				_hasUpdated = false;
				UpdateManager.RemoveAction(OnUpdated);
			}

			UpdatePointerEvents(true);

			if (_region != null)
			{
				_scrollable.Motion.ReleaseSimulation();
				_region = null;
			}

			_scrollable = null;

			base.OnUnrooted();
		}

		[Obsolete]
		public bool UserScroll
		{
			get { return ScrollableUserScroll; }
			set
			{
				//DEPRECATED: 2017-03-04
				Fuse.Diagnostics.Deprecated( "This value bound to the ScrollView now, set ScrollView.UserScroll instead", this );
			}
		}

		//this exists just so `UserScroll` can be `Obsolete` for a few releases
		bool ScrollableUserScroll
		{
			get { return _scrollable != null ? _scrollable.UserScroll : true; }
		}

		bool _pointerListening;
		Gesture _gesture;
		void UpdatePointerEvents(bool forceOff = false)
		{
			var shouldListen = !forceOff && _scrollable != null && ScrollableUserScroll;
			if (shouldListen == _pointerListening)
				return;

			if (shouldListen)
			{
				if (_gesture != null)
					Fuse.Diagnostics.InternalError( "inconsistent gesture state" );
				else
					_gesture = Input.Gestures.Add( this, _scrollable, GestureType.Primary | GestureType.NodeShare);
				// mouse wheel support
				Pointer.WheelMoved.AddHandler(_scrollable, OnPointerWheelMoved);
			}
			else if (_scrollable != null)
			{
				if (_gesture == null)
					Fuse.Diagnostics.InternalError( "inconsistent gesture state" );
				else
				{
					Pointer.WheelMoved.RemoveHandler(_scrollable, OnPointerWheelMoved);
					_gesture.Dispose();
					_gesture = null;
				}
			}
			else
			{
				throw new Exception( "Invalid tear-down of pointer events" );
			}

			_pointerListening = shouldListen;
		}

		bool _hasUpdated;
		bool _updateFirstFrame;
		void CheckNeedUpdated(bool off = false)
		{
			bool needUpdated = _region != null && !_region.IsStatic && IsRootingStarted;
			if (needUpdated == _hasUpdated)
				return;

			if (needUpdated)
			{
				UpdateManager.AddAction(OnUpdated);
				_hasUpdated = true;
				_updateFirstFrame = true;
			}
			else if (off)
			{
				UpdateManager.RemoveAction(OnUpdated);
				_hasUpdated = false;
			}
		}

		int _down = -1;
		//these are in Window coordinates to track better if it sizes/moves during dragging
		float2 _pointerPos, _prevPos;
		float2 _startPos;
		double _prevTime;

		internal float2 TestTargetDestination
		{
			get { return _region != null ? _region.Destination : float2(0); }
		}

		float2 _softCaptureStart;
		float2 _softCaptureCurrent;

		float _significance;

		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				return new GesturePriorityConfig(
					_scrollable == null ? GesturePriority.Low : _scrollable.GesturePriority,
					(!DelayStart ? 100 : 0) + _significance);
			}
		}

		bool _pressed;
		void StartInvalidateVisual()
		{
			if (!_pressed)
				UpdateManager.AddAction(_scrollable.InvalidateVisual);
			_pressed = true;
		}

		void StopInvalidateVisual()
		{
			if (_pressed)
				UpdateManager.RemoveAction(_scrollable.InvalidateVisual);
			_pressed = false;
		}

		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs args)
		{
			StartInvalidateVisual();
			//TODO: the use of 100 is kind of magical!
			_significance = Vector.Length(_region.Velocity) > hardCaptureVelocityThreshold ? 100 : 0;
			return GestureRequest.Capture;
		}

		void IGesture.OnCaptureChanged( PointerEventArgs args, CaptureType how, CaptureType prev )
		{
			if (how.HasFlag(CaptureType.Soft))
				_softCaptureStart = _softCaptureCurrent = args.WindowPoint;

			StartInvalidateVisual();
			_pointerPos = args.WindowPoint;
			_prevPos = _startPos = _pointerPos;
			_prevTime = args.Timestamp;

			_velocity.Reset( FromWindow(_pointerPos), float2(0));
			_region.StartUser();
			_region.Position = _scrollable.ScrollPosition;
			CheckNeedUpdated();
		}

		float2 FromWindow(float2 p)
		{
			return _scrollable.Parent.WindowToLocal(p);
		}

		void IGesture.OnLostCapture( bool forced )
		{
			StopInvalidateVisual();
			_significance = 0;
			if (_region != null && _region.IsUser)
				_region.EndUser();
			CheckNeedUpdated();
		}

		static SwipeGestureHelper _horizontalGesture = new SwipeGestureHelper(
			1, //since it can't deal with 0
			new DegreeSpan(45.0f, 135.0f),	// Right
			new DegreeSpan(-45.0f, -135.0f));	// Left

		static SwipeGestureHelper _verticalGesture = new SwipeGestureHelper(
			1,
			new DegreeSpan(-45.0f, 45.0f),
			new DegreeSpan(-135.0f, -180.0f),
			new DegreeSpan( 135.0f,  180.0f));

		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs args)
		{
			if (_gesture == null)
				return GestureRequest.Ignore;

			if (!_gesture.IsHardCapture)
			{
				_softCaptureCurrent = args.WindowPoint;
				_significance = 0;
				var diff = _softCaptureCurrent - _softCaptureStart;
				if (_scrollable.AllowedScrollDirections == ScrollDirections.Both)
				{
					_significance = Vector.Length(diff);
				}

				if (_scrollable.AllowedScrollDirections == ScrollDirections.Horizontal)
				{
					if (_horizontalGesture.IsWithinBounds(diff))
						_significance = Math.Abs(diff.X);

				}
				if (_scrollable.AllowedScrollDirections == ScrollDirections.Vertical)
				{
					if (_verticalGesture.IsWithinBounds(diff))
						_significance = Math.Abs(diff.Y);
				}
			}

			_pointerPos = args.WindowPoint;
			MoveUser( !_delayStart || _gesture.IsHardCapture ? MoveUserFlags.Started : MoveUserFlags.None,
				args.Timestamp);
			return GestureRequest.Capture;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs args)
		{
			StopInvalidateVisual();

			if (_delayStart && !_gesture.IsHardCapture)
				return GestureRequest.Cancel;

			//something may have taken over the movement mode (like Goto)
			if (_region.IsUser)
			{
				_pointerPos = args.WindowPoint;
				MoveUser( MoveUserFlags.Started | MoveUserFlags.Release, args.Timestamp );

				_region.EndUser( -_scrollable.ConstrainExtents(_velocity.CurrentVelocity) );
			}

			return GestureRequest.Cancel;
		}

		void OnPointerWheelMoved(object sender, PointerWheelMovedArgs args)
		{
			_region.StartUser();
			_region.Position = _scrollable.ScrollPosition;
			_region.StepUser( -args.WheelDelta );
			UpdateScrollMax();
			_region.Update( Time.FrameInterval );
			_scrollable.SetScrollPosition(Math.Min(Math.Max(_region.Position, _scrollable.MinScroll), _scrollable.MaxScroll), this);
			_region.EndUser();
		}

		//call if the size/position changed in response to a non-user event (like resize)
		public void CheckLimits()
		{
			UpdateScrollMax();
			//any already active region will respond to the updated bounds on its own
			if (_region != null && _region.IsStatic && !_region.IsUser)
				Goto(_scrollable.ScrollPosition);
		}

		Visual _pendingBringIntoView;
		void OnRequestBringIntoView(object sender, RequestBringIntoViewArgs args)
		{
			//defer to post layout and post input
			_pendingBringIntoView = args.Visual;
			UpdateManager.AddDeferredAction( PerformBringIntoView, UpdateStage.Layout,
				LayoutPriority.Post);
		}

		void PerformBringIntoView()
		{
			if (_pendingBringIntoView == null || !_pendingBringIntoView.IsRootingCompleted)
				return;

			var pos = _scrollable.GetVisualScrollPosition(_pendingBringIntoView);
			Goto(pos);
        	_pendingBringIntoView = null;
		}

		public void Goto( float2 position )
		{
			if (_scrollable == null)
				return;

			position = _scrollable.Constrain(position); //to avoid mismatch on pixel-snapping
			UpdateScrollMax();
			if (_region != null)
			{
				if (_region.IsStatic)
					_region.Position = _scrollable.ScrollPosition;
				_region.MoveTo( position );
			}
			CheckNeedUpdated();
		}

		//TODO: it's be a lot saner for the IScrollable to report that Max/Min have changed!
		void UpdateScrollMax()
		{
			if (_scrollable == null)
				return;

			if (_region != null)
			{
				_region.MaxPosition = _scrollable.MaxScroll;
				_region.MinPosition = _scrollable.MinScroll;
			}
		}

		void OnUpdated()
		{
			//this ensures that any explicitly set values are rendered at least once, preventing the
			//first frame double jump on mouse release, and allowing per-frames explicit updates to dominate
			if (_updateFirstFrame)
			{
				_updateFirstFrame = false;
				return;
			}

			if (_region == null || _scrollable == null)
			{
				Fuse.Diagnostics.InternalError( "Invalid scroller update" );
				return;
			}

			UpdateScrollMax();
			_region.Update( Time.FrameInterval );
			_scrollable.SetScrollPosition(_region.Position, this);
			//allow turning off update now, this ensures we always get one update when _region changed
			CheckNeedUpdated(true);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector sel)
		{
			if (obj != _scrollable)
				return;

			if (sel == ScrollView.UserScrollName)
				UpdatePointerEvents();
		}

		void OnScrollPositionChanged(object s, ScrollPositionChangedArgs args)
		{
			if (args.Origin == this)
				return;

			if (args.IsAdjustment)
				_region.Adjust(args.ArrangeOffset);
			else
				_region.Reset(args.Value);

			CheckNeedUpdated(true); //allow remove of Update
		}

		[Flags]
		enum MoveUserFlags
		{
			None = 0,
			Started = 1<<0,
			Release = 1<<1,
		}

		void MoveUser(MoveUserFlags flags, double time)
		{
			//this should essentially keep the movement tied to screen movements, not scroller relative,
			//yet still allow rotations to work correctly
			var diff = FromWindow(_prevPos)-FromWindow(_pointerPos);
			//mainly for iOS where Released still has movement in the event
			if (flags.HasFlag(MoveUserFlags.Release))
				diff = float2(0);
			_prevPos = _pointerPos;

			//var t = Clock.GetSeconds();
			var elapsed = time - _prevTime;
			_prevTime = time;

			if (flags.HasFlag(MoveUserFlags.Started))
			{
				//move relative to current always, in case it's changed (like sizing/removed)
				_region.Position = _scrollable.ScrollPosition;
				_region.StepUser( diff );
				OnUpdated();
			}
			_velocity.AddSample( FromWindow(_pointerPos), (float)elapsed,
				(!flags.HasFlag(MoveUserFlags.Started) ? SampleFlags.Tentative : SampleFlags.None) |
				(flags.HasFlag(MoveUserFlags.Release) ? SampleFlags.Release : SampleFlags.None) );
		}

		public float2 OverflowExtent
		{
			get { return _scrollable == null ? float2(0) : _scrollable.Motion.OverflowExtent; }
		}

	}
}
