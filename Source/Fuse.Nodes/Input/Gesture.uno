using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Input
{
	/**
		Priority helps determine which gesture to select if multiple gestures can be captured by the same pointer input.  This applies when two or more gestures are both matching the current user input (such as a Swipe, ScrollView, and Slider all handling a swipe to the right). The item with the highest priority will be used.

		This is not a strict ordering: lower priority gestures can still become active if their `Significance` value is sufficiently higher than a higher priority gesture. The one with more signficance is generally considered a better match even if low priority.
		
		@experimental
		@advanced
	*/
	public enum GesturePriority
	{
		Lowest = 0,
		Low,
		Normal,
		High,
		Highest,
	}
	
	/**	
		@experimental
		@advanced
	*/
	public struct GesturePriorityConfig
	{
		public GesturePriority Priority;
		public float Significance;
		public int Adjustment;
		
		public GesturePriorityConfig( GesturePriority priority,
			float significance = 0, int adjustment = 0)
		{
			Priority = priority;
			Significance = significance;
			Adjustment = adjustment;
		}
	}
	
	
	/**
		Feedback to the gesture about pointer events as well as priority feedback to the gesture handler.
		
		@experimental
		@advanced
	*/
	public interface IGesture
	{
		GestureRequest OnPointerPressed( PointerPressedArgs args );
		GestureRequest OnPointerMoved( PointerMovedArgs args );
		GestureRequest OnPointerReleased( PointerReleasedArgs args );

		/**
			Obtains the priority settings of the gesture.
			
			These values may change during the handling of a gesture. If a handler recognizes multiple gestures or compound gestures, it may decide to change the priority during handling.
			
			## priority
			
			The primary priority of the gesture. 
			
			## significance 
			
			The intended visual significance of the gesture, if applied, based on the current pointer feedback. This is a value measured in points.
			
			For example, if the point has moved 5 points to the left, a Swiper may report 5 to indicate how much it would move (this is a logical movement, since the true animation depends on the animators and triggers being used).
			
			## adjustment
			
			An adjustment can be used to adjust the ordering between two gestures that have the same priority. This adjust the order in which captures may be elevated, giving the one with a higher adjustment first chance to escalated to a hard capture.
			
			It's used, for example, to resolve that edge swipes resolve prior to directional swipes even if the SwipeGesture's are in different nodes.
			
			This should generally return `0`. A typical control will not modify this value.			
		*/
		GesturePriorityConfig Priority { get; }
		
		/**
			Called anytime CaptureType changes, except to None (in which case OnLostCapture would be called).
			
			An IGesture implementation should avoid making any visual changes until it obtains a Hard capture. Prior to this point it is uncertain if the gesture will actually be the selected one.  Gestures that only ever need a soft capture can however proceed, but they shouldn't be making any direction visual changes anway.
		*/
		void OnCaptureChanged( PointerEventArgs args, CaptureType howNew, CaptureType howPrev );
		
		/**
			Called whenever a previous capture is lost, soft or hard.
			
			It must be expected that this can be called at anytime. An IGesture implementation must be able to deal with lost captures at the start, middle, or end of a gesture, even if it's started making visual changes.
			
			@param forced False if the capture is lost due to a cancel request by the gesture. True otherwise, in cases such as it losing priority or the app losing focus.
		*/
		void OnLostCapture( bool forced );
	}
	
	[Flags]
	/** 
		@experimental
		@advanced
	*/
	public enum GestureType
	{
		//activates on any pointer index
		Any = 0<<0,
		//activates only on the primary pointer press
		Primary = 1 << 0,
		//allows multiple pointers to be depressed at the same time, otherwise only one is allowed
		Multi = 1 << 1,
		//adds CaptureType.Children to captures
		Children = 1 << 2,
		//adds CaptureType.NodeShare to captures
		NodeShare = 1 << 3,
	}

	/**
		An IGesture indicates how it handles a request by returning one of these values.
	*/
	public enum GestureRequest
	{
		//this event was not considered
		Ignore,
		//the gesture should be capturing now
		Capture,
		//the current capture, if any, should be cancelled
		Cancel,
	}
	
	//internals are all for the `Gestures` class
	/**
		The binding between an IGesture and the Gestures manager. A Gesture represents the ability of a handler to detect, and use, pointer input within a node.
		
		An IGesture is primarily a slave to the Gestures management. Whether it gets a capture, soft or hard, and when it loses/escalates the capture, are at the whims of this system.
		
		@experimental
		@advanced
	*/
	public class Gesture : IPropertyListener
	{
		internal readonly IGesture Handler;
		internal readonly GestureType Type;
		internal readonly Visual Target;
		
		CaptureType _captureType = CaptureType.None;
		List<int> _down = new List<int>();

		internal Gesture(IGesture handler, GestureType type, Visual target)
		{
			if (handler == null)
				throw new ArgumentNullException( nameof(handler) );

			if (target == null)
				throw new ArgumentNullException( nameof(target) );

			Handler = handler;
			Type = type;
			Target = target;
		}

		void HandleRequest( GestureRequest req, PointerEventArgs args )
		{
			switch (req)
			{
				case GestureRequest.Ignore: break;
				case GestureRequest.Capture: Capture(args); break;
				case GestureRequest.Cancel: Cancel(); break;
			}
		}
		
		static internal float HardCaptureSignificanceThreshold { get { return 10; } }
		
		void Capture( PointerEventArgs args )
		{
			var pr = Handler.Priority;
			var sig = pr.Significance;
			
			CaptureType captureType = (sig >= HardCaptureSignificanceThreshold 
				|| _captureType.HasFlag(CaptureType.Hard)) ? CaptureType.Hard : CaptureType.Soft;
			if (Type.HasFlag(GestureType.Children))
				captureType |= CaptureType.Children;
			if (Type.HasFlag(GestureType.NodeShare))
				captureType |= CaptureType.NodeShare;
				
			Gestures.AddActive(this);
			Gestures.RequestCaptureChange(this, args, captureType);
		}
				
		internal void OnRequestChanged( PointerEventArgs args, CaptureType captureType )
		{
			//keep current state
			if (_captureType == captureType && _down.Contains(args.PointIndex))
				return;

			if ( (_captureType == CaptureType.None) ?
				!Pointer.ModifyCapture(this, Target, OnLostCapture, captureType, args.PointIndex) :
				!Pointer.ModifyCapture(this, captureType) )
			{
				OnLostCapture();
				return;
			}
				
			if (!_down.Contains(args.PointIndex))
			{
				_down.Add(args.PointIndex);
				if (_down.Count > 1)
				{
					if (!Pointer.ExtendCapture(this, args.PointIndex))
					{
						OnLostCapture();
						return;
					}
				}
			}
					
			var prevCapture = _captureType;
			_captureType = captureType;
			
			if (captureType.HasFlag(CaptureType.Hard))
				Target.BeginInteraction(this, OnLostCapture);
				
			Handler.OnCaptureChanged( args, captureType, prevCapture );
		}
		
		/**
			@return true if the gesture currently has a hard capture. false otherwise.
		*/
		public bool IsHardCapture
		{
			get { return _captureType.HasFlag(CaptureType.Hard); }
		}
		
		void OnLostCapture()
		{
			LostCapture(true);
		}
		
		void LostCapture(bool forced)
		{
			_down.Clear();
			_captureType = CaptureType.None;
			Gestures.RemoveActive(this);
			Pointer.ReleaseCapture(this);
			Target.EndInteraction(this);
			Handler.OnLostCapture(forced);
		}
		
		void Cancel()
		{
			//on mobile we can't have a capture without a pressed button, therefore this check is okay
			//it wouldn't be okay if we allowed captures without a button being pressed
			if (_down.Count == 0)
				return;
				
			LostCapture(false);
		}
		
		internal void OnPointerPressed( object sender, PointerPressedArgs args )
		{
			Gestures.PumpEvent(args);

			if (_down.Count != 0 && !Type.HasFlag(GestureType.Multi))
				return;

			if (Type.HasFlag(GestureType.Primary) && !args.IsPrimary)
				return;
				
			HandleRequest( Handler.OnPointerPressed( args ), args );
		}
		
		internal void OnPointerMoved( object sender, PointerMovedArgs args )
		{
			Gestures.PumpEvent(args);

			if (!_down.Contains(args.PointIndex))
				return;

			//this means Pointer is broken, we should have got a LostCapture callback				
			if (!Pointer.IsPressed(args.PointIndex))
			{
				Fuse.Diagnostics.InternalError( "Missing LostCapture on " + args.PointIndex, this );
				LostCapture(true);
				return;
			}
			
			HandleRequest(Handler.OnPointerMoved( args ), args);
		}
		
		internal void OnPointerReleased( object sender, PointerReleasedArgs args )
		{
			Gestures.PumpEvent(args);

			if (!_down.Contains(args.PointIndex))
				return;
				
			HandleRequest(Handler.OnPointerReleased( args ), args);
			//there's no guarantee the capture was cancelled, but the down button is certainly gone
			_down.Remove(args.PointIndex);
			//TODO: There's currently no way to remove a PointIndex from the capture (for multi-touch)
			//though a defect, this was the case before as well. It will likely come up if more multi-touch
			//gestures are created (and the iOS issue is fixed where any release causes all touches to release)
		}

		/**
			Removes support of this gesture from the system. 
			
			This typically happens during unrooting, but could happen prior to that point.
		*/
		public void Dispose()
		{
			Cancel();
			Gestures.Remove(Handler);
		}
		
		//This interface is expose to allow this gesure to be the source of changes
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector sel) {}
		
		/* How far away from the intended vector direction a position can be before it's no longer considered part of that gesture. 44 being the Apple minimum for tappable regions, so it also seems reasonable as a constraint people can stay within.*/
		const float _vectorOffsetThreshold = 44;
		
		/**
			Calculates the significance of an offset relative to a vector.
			
			This will return 0 if the orthogonal distance becomes too large -- indicating it's not movement along the vector anymore.
		*/
		static public float VectorSignificance( float2 vector, float2 offset )
		{
			if (Internal.VectorUtil.NormRejection( offset, vector ) > _vectorOffsetThreshold)
				return 0;
			return Math.Abs(Internal.VectorUtil.ScalarProjection( offset, vector ));
		}
	}
	
	/**
		This is currently a transition mechanism as we move pointer handling from direct handlers to a structured gesture system. This will be the preferred mechanism for handling nearly all pointer input.
		
		Gestures are a unified way to handle pointer input from the user. They coordinate their activation and can resolve exclusions and priorities, ensuring the correct gesture is handled.

		Though the Gesture system is still considered experimental it is the preferred way of handling pointer input now. The API is relatively stable, but small adjustments might be made to handle more complex gestures.
				
		@experimental
		@advanced
	*/
	static public class Gestures
	{
		static Dictionary<IGesture,Gesture> _gestures = new Dictionary<IGesture,Gesture>();

		/**
			Adds a gesture handler to the target.
			
			This is typically done during rooting, but could happen after that time.
			
			@return The bound gesture. Use `.Dispose` to remove the gesture support.
		*/
		static public Gesture Add( IGesture handler, Visual target, GestureType type )
		{
			if (handler == null)
				throw new ArgumentNullException( nameof(handler) );

			if (_gestures.ContainsKey(handler))
				throw new ArgumentException( "This gesture handler is already registered" );
				
			var g = new Gesture(handler, type, target);
			_gestures[handler] = g;
		
			//ideally we will merge this into the generate pointer handling to avoid needing an extra
			//object layer for gestures (or at least support a unified interface for handlers, no `Action` events)
			Pointer.Pressed.AddHandler(target, g.OnPointerPressed);
			Pointer.Released.AddHandler(target, g.OnPointerReleased);
			Pointer.Moved.AddHandler(target, g.OnPointerMoved);
			
			return g;
		}
		
		static internal void Remove( IGesture handler )
		{
			Gesture g;
			if (!_gestures.TryGetValue(handler, out g))
				throw new ArgumentException( "Unregistered gesture" );
				
			Pointer.Pressed.RemoveHandler(g.Target, g.OnPointerPressed);
			Pointer.Released.RemoveHandler(g.Target, g.OnPointerReleased);
			Pointer.Moved.AddHandler(g.Target, g.OnPointerMoved);
			_gestures.Remove(handler);
		}
		
		class ActiveGesture
		{
			public Gesture Gesture;
			public bool ChangeRequest;
			public PointerEventArgs Args;
			public CaptureType CaptureType;
			public float Significance;
			public int PriorityAdjustment;
			public GesturePriority Priority;
		}
		
		static List<ActiveGesture> _activeGestures = new List<ActiveGesture>();
		static bool _changePosted;
		
		static internal void RequestCaptureChange( Gesture gesture, PointerEventArgs args, 
			CaptureType captureType )
		{
			var index = GetActiveGestureIndex(gesture);
			if (index == -1)
				throw new Exception("RequestCaptureChange on inactive gesture" );
			
			var ar = _activeGestures[index];
			ar.ChangeRequest = true;
			ar.Args = args;
			ar.CaptureType = captureType;
				
			if (!_changePosted) 
			{
				UpdateManager.AddDeferredAction( ProcessCaptureChanges );
				_changePosted = true;
			}
		}

		static PointerEventArgs _pumpArgs;
		/**
			Before processing subsequent events the previous ones need to complete. This is important when multiple events arrive in a single frame. This works by comparing the "args" object to the previous one. Each event represents a full set of processing, thus if a new event shows up it must conclude the previous one.

			It'd likely be cleaner for the Gestures to hook directly into the Pointer.Input system rather than relying on PumpEvent to be called. This was this easier approach for now.
		*/
		static internal void PumpEvent( PointerEventArgs args )
		{
			if (_pumpArgs == null)
			{
				_pumpArgs = args;
				return;
			}

			if (_pumpArgs == args)
				return;
			_pumpArgs = args;

			if (!_changePosted)
				return;

			ProcessCaptureChanges();
			_changePosted = false;
		}
		
		static int PriorityOrder( ActiveGesture a, ActiveGesture b )
		{
			var p = (int)(b.Priority) - (int)(a.Priority);
			if (p != 0)
				return p;
				
			return b.PriorityAdjustment - a.PriorityAdjustment;
		}
		
		static void UpdateSignificance()
		{
			for (int i=0; i < _activeGestures.Count; ++i)
			{
				var ar = _activeGestures[i];
				var pr = ar.Gesture.Handler.Priority;
				ar.Priority = pr.Priority;
				ar.Significance = pr.Significance;
				ar.PriorityAdjustment = pr.Adjustment;
			}
		}
		
		static void ProcessCaptureChanges()
		{
			if (!_changePosted)	
				return;
			_changePosted = false;

			UpdateSignificance();
			_activeGestures.Sort( PriorityOrder );

			for (int i=0; i < _activeGestures.Count; ++i) 
			{
				var ar = _activeGestures[i];
				if (!ar.ChangeRequest)
					continue;
				ar.ChangeRequest = false;
					
				var prev = i > 0 ? _activeGestures[i-1] : null;
				var pdiff = prev != null ? prev.Priority - (int)ar.Priority : 0;
				if (pdiff > 0 && ar.CaptureType.HasFlag(CaptureType.Hard) )
				{
					//lower priority must beat out higher by enough to do anything.
					if (ar.Significance < ( (int)prev.Priority * 2.0f + prev.Significance))
					{
						continue;
					}
				}
				ar.Gesture.OnRequestChanged( ar.Args, ar.CaptureType );
			}
		}

		static int GetActiveGestureIndex( Gesture g )
		{
			for (int i=0; i < _activeGestures.Count; ++i)
			{
				if (_activeGestures[i].Gesture == g)
					return i;
			}
			
			return -1;
		}
		
		internal static void AddActive( Gesture g )
		{
			var index = GetActiveGestureIndex(g);
			if (index == -1)
				_activeGestures.Add( new ActiveGesture{ Gesture = g });
		}
		
		internal static void RemoveActive( Gesture g )
		{
			var index = GetActiveGestureIndex(g);
			if (index != -1)
				_activeGestures.RemoveAt(index);
		}
	}
}
