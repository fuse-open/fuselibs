using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Diagnostics;

using Fuse.Elements;
using Fuse.Input;
using Fuse.Internal;
using Fuse.Motion.Simulation;

namespace Fuse.Gestures.Internal
{
	enum SwipeRegionArea
	{	
		All,
		Vector,
	}

	class SwipeRegion: PropertyObject, IPropertyListener
	{
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop) { }

		const float _zeroTolerance = 1e-05f;

		bool _isEnabled = true;
		public bool IsEnabled
		{
			get { return _isEnabled; }
			set { _isEnabled = value; }
		}
		
		GesturePriority _gesturePriority = GesturePriority.Low;
		public GesturePriority GesturePriority
		{
			get { return _gesturePriority; }
			set { _gesturePriority = value; }
		}
		
		double _progress;
		public double Progress
		{	
			get { return _progress; }
		}
		
		double _stableProgress;
		public double StableProgress
		{
			get { return _stableProgress; }
		}

		public enum ProgressFlags
		{
			None = 0,
			Interacting = 1 << 0,
			EndProgress = 1 << 1,
		}

		internal static Selector InProgressName = "InProgress";
		bool _inProgress = false;
		public bool InProgress 
		{ 
			get { return _inProgress; }
			private set
			{
				if (value == _inProgress)
					return;
					
				_inProgress = value;
				OnPropertyChanged(InProgressName);
			}
		}
		
		public void SetActive(bool active)
		{
			SetProgress(active ? 1 : 0, ProgressFlags.EndProgress);
		}

		internal static Selector ProgressName = "Progress";
		internal bool SetProgress(double value, ProgressFlags flags = ProgressFlags.None)
		{
			var interacting = flags.HasFlag(ProgressFlags.Interacting);
			var endProgress = flags.HasFlag(ProgressFlags.EndProgress);
			
			//don't check value == _progress since we need to send messages
			_progress = value;
			OnPropertyChanged(ProgressName);

			InProgress = !endProgress;
			
			//expect to be called later without interacting flag
			if (interacting && !AutoTrigger)
				return false;
				
			bool swiped = false;
			
			if (endProgress)
			{
				//truncate _progress
				if (Math.Abs(_progress) < _zeroTolerance)
					_progress = 0;
				else if (Math.Abs(_progress-1) < _zeroTolerance)
					_progress = 1;
				else
					Fuse.Diagnostics.InternalError("Unexpected progress in swipe", this );
				
				bool active = _progress == 1;
				bool cancelled = _stableProgress == _progress;
				if (TriggerSwipe || AutoTrigger)
				{
					UpdateManager.AddDeferredAction(
						new DoSwiped{
							Active = active,
							Region = this,
							Cancelled = cancelled }.Perform );
					TriggerSwipe = false;
					swiped = true;
				}
					
				_stableProgress = _progress;
				if (active && RevertActive)
					UpdateManager.AddDeferredAction(DoRevertActive, LayoutPriority.Post);
			}
			return swiped;
		}
		
		internal bool TriggerSwipe;
		
		//only sent when the user completes an activation (they swipe) <Active,Cancelled>
		public event Action<bool, bool> Swiped;
		
		static Selector _isActiveName = "IsActive";
		bool _isActive;
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
			OnPropertyChanged(_isActiveName);
		}

		void DoRevertActive()
		{
			SetProgress(0, ProgressFlags.EndProgress);
			PointBody1D.Reset(0);

			IsActive = false;
		}
		
		class DoSwiped
		{
			public bool Active;
			public SwipeRegion Region;
			public bool Cancelled;
			
			public void Perform()
			{
				if (Region.Swiped != null)
					Region.Swiped(Active, Cancelled);
			}
		}
		
		//expected to be a unit vector. The primary direction of the swipe
		public float2 Direction;

		//the accepted range of motion (angle from Direction) for this region to match
		public float Range = Math.DegreesToRadians(30);
		
		public readonly DestinationSimulation<float> PointBody1D = SmoothSnap<float>.CreateNormalized();
		
		public bool IsStatic
		{
			get { return PointBody1D.IsStatic; }
		}
		
		public bool IsSelectable
		{
			get { return (IsStatic || IsInterruptible) && IsEnabled; }
		}
		
		public SwipeRegionArea Area;

		//hit area is the region around this line
		public float4 AreaVector;
		//up to this distance away
		public float AreaVectorDistance = 100;
		
		//lower priority has precedence during activation
		public int Priority = 0;

		//a fixed point length of the swiping range
		public double Length = 100;
		//swiping length comes from the ActualSize of this element (Dot product with Direction)
		public Element LengthElement;

		//at which point does the panel finish opening/closing automatically
		public float ActivationThreshold = 1f;
		public float DeactivationThreshold = 0f;

		//can an active transition be interrupted by the user
		public bool IsInterruptible = true;
		
		//adjust time for snapping animation
		public  double TimeMultiplier = 1.0;
		
		//once active it reverts to inactive immediately (bypass mode)
		public bool RevertActive = false;
		
		//triggers swiped the moment it reaches full progress
		public bool AutoTrigger = false;
		
		public bool IsPointInside(Element prime, float2 coord)
		{
			if (Area == SwipeRegionArea.All)
				return true;
				
			if (Area == SwipeRegionArea.Vector)
			{
				var size = prime.ActualSize;
				
				if (coord.X < 0 || coord.Y < 0 || coord.X > size.X || coord.Y > size.Y)
					return false;
					
				var v = AreaVector * float4(size,size);
				var l = VectorUtil.DistanceLine(v, coord);
				//this extends the swipe area for revealed panels from the edge, to ensure the whole panel can be swiped
				return l < Math.Max(AreaVectorDistance, EffectiveLength * Progress);
			}
			
			return false;
		}
		
		public float ActivateStrength(float2 diff)
		{
			var l = Vector.Length(diff);
			if (l < _zeroTolerance)
				return 0;
				
			//only activate in the direction where it could move currently
			var a = VectorUtil.Angle(diff, Direction);
			if (Progress < 1 && a < Range/2)
				return l;
				
			if (Progress > 0 && a > (Math.PIf - Range/2))
				return l;
				
			return 0;
		}
		
		public float ScalarDistance(float2 diff)
		{
			return VectorUtil.ScalarProjection(diff, Direction);
		}
		
		double EffectiveLength
		{
			get
			{
				if (LengthElement == null)
					return Length;
				return Math.Abs(Vector.Dot( Direction, LengthElement.ActualSize ));
			}
		}
		
		public bool InteractProgress(float2 diff, double startProgress)
		{
			var l = ScalarDistance(diff);
			var p = Math.Clamp( l / EffectiveLength + startProgress, 0.0, 1.0);
			var flags = ProgressFlags.Interacting;
			if (AutoTrigger && p == 1)
				flags |= ProgressFlags.EndProgress;
			return SetProgress(p, flags);
		}
		
		public float ScalarValue(float2 x)
		{
			return VectorUtil.ScalarProjection(x, Direction);
		}
	}
	
	class Swiper : IGesture
	{
	
		int _attachCount = 1;
		Element _element;
		
		Swiper(Element elm)
		{
			_element = elm;
		}
		
		static readonly PropertyHandle _swiperProperty = Fuse.Properties.CreateHandle();
		static public Swiper AttachSwiper(Element elm)
		{
			object v;
			if (elm.Properties.TryGet(_swiperProperty, out v))
			{
				var s = v as Swiper;
				s._attachCount++;
				return s;
			}
			
			var ns = new Swiper(elm);
			elm.Properties.Set(_swiperProperty, ns);
			ns.OnRooted(elm);
			return ns;
		}
		
		public void Detach()
		{
			_attachCount--;
			if (_attachCount == 0)
			{
				_element.Properties.Clear(_swiperProperty);
				OnUnrooted();
			}
		}
		
		//set once the interacting region is identified
		SwipeRegion _pointerRegion;
		//excluded on selection
		SwipeRegion _excludeRegion;
		//added during pointer down, contains all regions that might be considered
		List<SwipeRegion> _pointerRegions = new List<SwipeRegion>();
		List<SwipeRegion> _regions = new List<SwipeRegion>();
		
		public void AddRegion(SwipeRegion region)
		{
			int i=0;
			for (i=0; i < _regions.Count; ++i)
				if (_regions[i].Priority > region.Priority)
					break;
			
			_regions.Insert(i, region);
			CheckNeedUpdated();
		}
		
		public void RemoveRegion(SwipeRegion region)
		{
			_regions.Remove(region);
			CheckNeedUpdated();
		}
		
		Gesture _gesture;
		void OnRooted(Element n)
		{
			_pointerRegion = null;
			_pointerRegions.Clear();
			
			_element = n;
			_gesture = Input.Gestures.Add( this, _element, GestureType.Primary | GestureType.NodeShare);
		}

		void OnUnrooted()
		{
			_gesture.Dispose();
			_element =  null;
		}
		
		bool _hasUpdated;
		void CheckNeedUpdated(bool off = false)
		{
			bool needUpdated = false;
			for (int i=0; i < _regions.Count; ++i)
			{
				var region = _regions[i];
				if (!region.IsStatic)
				{
					needUpdated = true;
				}
				else if (region.InProgress)
				{
					//unexpected, but cleanup any items that don't need animation but had pending progress
					Fuse.Diagnostics.InternalError( "incomplete swipe detected", this );
					region.SetProgress( region.StableProgress, SwipeRegion.ProgressFlags.EndProgress );
				}
			}
				
			if (needUpdated == _hasUpdated)
				return;
				
			if (needUpdated)
			{
				UpdateManager.AddAction(OnUpdated);
				_hasUpdated = true;
			}
			else if (off)
			{
				UpdateManager.RemoveAction(OnUpdated);
				_hasUpdated = false;
			}
		}

		void OnUpdated()
		{
			for (int i=0; i < _regions.Count; ++i)
			{
				var region = _regions[i];
				if (region.IsStatic && !region.InProgress)
					continue;
					
				if (!region.IsStatic)
					region.PointBody1D.Update( Time.FrameInterval * region.TimeMultiplier );
				region.SetProgress(region.PointBody1D.Position, 
					region.IsStatic ? SwipeRegion.ProgressFlags.EndProgress : SwipeRegion.ProgressFlags.None);
			}
			CheckNeedUpdated(true);
		}
		
		void IGesture.OnLostCapture(bool forced)
		{
			_significance = 0;
			if (forced)
			{
				for (int i=0; i < _pointerRegions.Count; ++i)
					_pointerRegions[i].PointBody1D.Position = (float)_pointerRegions[i].Progress;
				if (_pointerRegion != null)
					_pointerRegion.PointBody1D.Position = (float)_pointerRegion.Progress;
			}
			CheckNeedUpdated();
		}

		double _startProgress;
		double _prevTime;
		float2 _startCoord;
		float _velocityThreshold = 300.0f;
		
		PointerVelocity<float2> _velocity = new PointerVelocity<float2>();
		
		float _significance;
		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				return new GesturePriorityConfig(
					_pointerRegion == null ? GesturePriority.Normal : _pointerRegion.GesturePriority,
					_significance,
					//TODO: fixup random number based on priorities in Swipe somehow
					_pointerRegion == null ? 0 : (_pointerRegion.Priority < 100 ? 1 : 0) );
			}
		}
		
		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs args)
		{
			var coord = FromWindow(args.WindowPoint);
			_prevTime = args.Timestamp;
			_pointerRegions.Clear();
			_pointerRegion = null;
			_excludeRegion = null;
			_significance = 0;
			for (int i=0; i < _regions.Count; ++i)
			{
				var region = _regions[i];
				if (region.IsSelectable && region.IsPointInside(_element, coord))
					_pointerRegions.Add(region);
			}
			if (_pointerRegions.Count == 0)
				return GestureRequest.Ignore;
			return GestureRequest.Capture;
		}
		
		void IGesture.OnCaptureChanged(PointerEventArgs args, CaptureType how, CaptureType prev)
		{
			if (_pointerRegions.Count == 0)
			{
				Fuse.Diagnostics.InternalError( "invalid OnCapture" );
				return;
			}
			
			//actual movement is deferred from point of capture
			RestartMove( FromWindow(args.WindowPoint) );
		}
		
		float2 FromWindow(float2 p)
		{
			if(_element == null || _element.Parent == null)
				return p;
			//use parent on the assumption that element itself might be moving
			return _element.Parent.WindowToLocal(p);
		}

		void MoveUser(float2 coord, double elapsed, bool release = false)
		{
			_velocity.AddSample( coord, (float)elapsed, 
				(!_gesture.IsHardCapture ? SampleFlags.Tentative : SampleFlags.None) |
				(release ? SampleFlags.Release : SampleFlags.None) );
		}
		
		void RestartMove(float2 currentCoord)
		{
			_startCoord = currentCoord;
			_velocity.Reset( _startCoord);
		}
		
		bool _allowNewRegion;
		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs args)
		{
			MoveUser(FromWindow(args.WindowPoint), args.Timestamp - _prevTime);

			var currentCoord = FromWindow(args.WindowPoint);
			_prevTime = args.Timestamp;
			
			//to allow a new region to start immediately
			for( int i=0; i<2;++i)
			{
				var diff = currentCoord - _startCoord;
				if (!_gesture.IsHardCapture || _allowNewRegion)
				{
					var selRegion = SelectRegion(diff);
					if (selRegion == _excludeRegion && _excludeRegion != null)
					{
						//measure from whenever direction changes, otherwise we get stuck as the angle is wrong
						RestartMove(currentCoord);
					}
					else if (selRegion != null && selRegion != _pointerRegion)
					{
						if (_pointerRegion != null)
						{
							SetActivation(_pointerRegion, _pointerRegion.StableProgress > 0.5f , false);
						}
						_excludeRegion = null;
						_pointerRegion = selRegion;
						
						_startProgress = _pointerRegion.Progress;
						currentCoord = FromWindow(args.WindowPoint);
						//diff needs to be reset to avoid a jump
						diff = currentCoord - _startCoord;
						_allowNewRegion = false;
					}
				}
				
				_significance = _pointerRegion == null ? 0f : Math.Abs(_pointerRegion.ScalarDistance(diff));
				
				//defer anything until region is identified
				if (_pointerRegion != null && _gesture.IsHardCapture)
				{
					if (_pointerRegion.InteractProgress(diff, _startProgress))
					{
						RestartMove(currentCoord);
						_excludeRegion = _pointerRegion;
						_pointerRegion = null;
						_allowNewRegion = true;
					}
					else if (!_allowNewRegion)
					{
						//allow new region to be selected if progress drops back to zero
						_allowNewRegion = _startProgress == 0 && _pointerRegion.Progress == 0;
						continue;
					}
				}

				break;
			}
			
			return GestureRequest.Capture;
		}
		
		SwipeRegion SelectRegion(float2 diff)
		{
			SwipeRegion sel = null;
			//currently active ones have higher priority (so that open/close work as expected)
			for (int i=0; i < _pointerRegions.Count; i++)
			{
				var region = _pointerRegions[i];
				var str = region.ActivateStrength(diff);
				if (str <= 0)
					continue;
				
				if (sel == null ||
					sel.Progress < region.Progress )
				{
					sel = region;
				}
			}
			
			return sel;
		}

		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs args)
		{	
			//if gesture not recognize return to current state
			if (!_gesture.IsHardCapture || _pointerRegion == null)
				return GestureRequest.Cancel;

			var currentCoord = FromWindow(args.WindowPoint);
			_pointerRegion.InteractProgress(currentCoord - _startCoord, _startProgress);
			MoveUser(currentCoord, args.Timestamp - _prevTime, true);

			var v = _pointerRegion.ScalarValue(_velocity.CurrentVelocity);
			var pdiff = _pointerRegion.Progress - _startProgress;
			bool on = false;
			if (v < -_velocityThreshold)
				on = false;
			else if (v > _velocityThreshold)
				on = true;
			else if (pdiff >= 0)
				on = _pointerRegion.Progress >= _pointerRegion.ActivationThreshold;
			else
				on = !(_pointerRegion.Progress <= _pointerRegion.DeactivationThreshold);

			SetActivation(_pointerRegion, on, false);
			return GestureRequest.Cancel;
		}
		
		public void SetActivation(SwipeRegion region, bool on, bool bypass = false)
		{
			var d = on ? 1.0f : 0.0f;
			if (d != region.PointBody1D.Destination)
			{
				region.PointBody1D.Destination = d;
				region.IsActive = on;
			}
			//always update position for snapping animation
			if (bypass)
			{
				region.PointBody1D.Position = d;
				region.SetProgress(d, SwipeRegion.ProgressFlags.EndProgress);
			}
			else
			{
				//we should trigger a swipe, but only once the progress reaches the end
				region.TriggerSwipe = true;

				region.PointBody1D.Position = (float)region.Progress;
				//force update in case progress hasn't actually changed (user swiped to exactly this position -- on ends)
				if (region.IsStatic)
					region.SetProgress(region.PointBody1D.Position, SwipeRegion.ProgressFlags.EndProgress);
			}
			CheckNeedUpdated();
		}
	}
}
