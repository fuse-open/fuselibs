using Uno;
using Uno.Diagnostics;

using Fuse.Elements;
using Fuse.Input;
using Fuse.Motion.Simulation;

namespace Fuse.Gestures.Internal
{
	internal class EdgeSwiper
	{
		public Edge Edge
		{
			get { return _edge; }
			set { _edge = value; }
		}

		public float EdgeThreshold
		{
			get { return _edgeThreshold; }
			set { _edgeThreshold = value; }
		}

		public Element Target
		{
			get { return _target; }
			set { _target = value; }
		}

		static readonly SwipeGestureHelper _leftRightSwipe = new SwipeGestureHelper(10.0f,
			new DegreeSpan(-45.0f, -135.0f),  // Right
			new DegreeSpan(45.0f, 135.0f)); // Left

		static readonly SwipeGestureHelper _upDownSwipe = new SwipeGestureHelper(10.0f,
			new DegreeSpan(135.0f, 180.0f), new DegreeSpan(-135.0f, -180.0f), // Up
			new DegreeSpan(-45.0f, 45.0f));

		readonly DestinationSimulation<float> _pointBody1D = SmoothSnap<float>.CreateNormalized();
		
		public event Action<object, double> ProgressChanged;
		
		public double Progress
		{
			get { return _progress; }
			private set 
			{ 
				_progress = Math.Max(value, 0.0); 
				if (ProgressChanged != null)
					ProgressChanged(this, _progress);
			}
		}
		
		public void Seek( double progress )
		{
			Progress = progress;
		}

		float _edgeThreshold = 32.0f;
		double _progress = 0.0;
		Edge _edge = Edge.Left;
		Element _target = null;

		float2 _previousCoord = float2(0.0f);
		float2 _currentCoord = float2(0.0f);
		float2 _startCoord = float2(0.0f);
		double _startProgress;
		double _prevTime;
		float _velocityThreshold = 300.0f;
		int _down = -1;
		bool _isHardCapture;
		
		PointerVelocity<float2> _velocity = new PointerVelocity<float2>();

		Element _element;
		public void Rooted(Element e)
		{
			_element = e;
			Pointer.Pressed.AddHandler(_element, OnPointerPressed);
			Pointer.Moved.AddHandler(_element, OnPointerMoved);
			Pointer.Released.AddHandler(_element, OnPointerReleased);
		}

		public void Unrooted()
		{
			Pointer.Pressed.RemoveHandler(_element, OnPointerPressed);
			Pointer.Moved.RemoveHandler(_element, OnPointerMoved);
			Pointer.Released.RemoveHandler(_element, OnPointerReleased);
		}

		public bool IsEnabled
		{
			get
			{
				return (Progress > 0.0 && _pointBody1D.IsStatic);
			}
		}
		
		public void Enable()
		{
			_pointBody1D.Destination = 1;
			CheckNeedUpdated();
		}

		public void Disable()
		{
			_pointBody1D.Destination = 0;
			CheckNeedUpdated();
		}
		
		bool _hasUpdated;
		void CheckNeedUpdated(bool off = false)
		{
			bool needUpdated = _down == -1 && !_pointBody1D.IsStatic;
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
			_pointBody1D.Update( Time.FrameInterval );
			Progress = _pointBody1D.Position;
			CheckNeedUpdated(true);
		}
		
		void OnLostCapture()
		{
			_down = -1;
			_isHardCapture = false;
			_pointBody1D.Position = (float)Progress;
			Pointer.ReleaseCapture(this);
			CheckNeedUpdated();
		}

		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			if (_down != -1 || !IsWithinSwipeBounds(args.WindowPoint))
				return;
			
			_isHardCapture = false;
			if (args.TrySoftCapture(this, OnLostCapture,_element))
			{
				_startProgress = Progress;
				_down = args.PointIndex;
				_prevTime = Clock.GetSeconds();
				_previousCoord = FromWindow(args.WindowPoint);
				_currentCoord = FromWindow(args.WindowPoint);
				_startCoord = FromWindow(args.WindowPoint);
				_velocity.Reset(_currentCoord, float2(0));
			}
		}
		
		float2 FromWindow(float2 p)
		{
			if(_element == null || _element.Parent == null)
				return p;
			//use parent on the assumption that element itself might be moving
			return _element.Parent.WindowToLocal(p);
		}

		void MoveUser(float2 coord, bool release = false)
		{
			_currentCoord = coord;
			//var diff = -(_currentCoord - _previousCoord);
			_previousCoord = coord;
		
			var t = Clock.GetSeconds();
			var elapsed = t - _prevTime;
			_prevTime = t;
			
			_velocity.AddSample( _currentCoord, (float)elapsed, 
				(!_isHardCapture ? SampleFlags.Tentative : SampleFlags.None) |
				(release ? SampleFlags.Release : SampleFlags.None) );
		}
		
		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			if (_down != args.PointIndex)
				return;

			MoveUser(FromWindow(args.WindowPoint));
			
			if (!_isHardCapture)
			{
				var diff = _currentCoord - _startCoord;
				var withinBounds = false;

				switch (Edge)
				{
					case Edge.Right:
					case Edge.Left:
						withinBounds = _leftRightSwipe.IsWithinBounds(diff);
						break;

					case Edge.Top:    
					case Edge.Bottom:
						withinBounds = _upDownSwipe.IsWithinBounds(diff);
						break;
				}

				if (withinBounds)
				{
					if (args.TryHardCapture(this, OnLostCapture,_element))
						_isHardCapture = true;
					else
						OnLostCapture();
				}
			}

			CalcProgress();
		}

		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			if (_down != args.PointIndex)
				return;
				
			//if gesture not recognize return to current state
			if (!_isHardCapture)
			{
				OnLostCapture();
				return;
			}

			MoveUser(FromWindow(args.WindowPoint), true);
			Pointer.ReleaseCapture(this);			

			var v = PrimaryValue(_velocity.CurrentVelocity);
			bool on = false;
			if (v < -_velocityThreshold)
				on = false;
			else if (v > _velocityThreshold)
				on = true;
			else if (Progress > 0.5f)
				on = true;
				
			_pointBody1D.Destination = on ? 1 : 0;
			_pointBody1D.Position = (float)Progress;
			
			_down = -1;
			_isHardCapture = false;
			CheckNeedUpdated();
		}


		bool IsWithinSwipeBounds(float2 windowPoint)
		{
			if (Target != null && Target.GetHitWindowPoint(windowPoint)!=null)
				return true;

			var coord = _element.WindowToLocal(windowPoint);
			var bounds = _element.ActualSize;
			var threshold = EdgeThreshold;

			switch (Edge)
			{
				case Edge.Left:
					return (coord.X >= 0 && coord.X <= threshold);

				case Edge.Right:
					return (coord.X <= bounds.X && coord.X >= bounds.X - threshold);

				case Edge.Top:
					return (coord.Y >= 0f && coord.Y <= threshold);

				case Edge.Bottom:
					return (coord.Y <= bounds.Y && coord.Y >= bounds.Y - threshold);
			}

			return false;
		}

		void CalcProgress()
		{
			var t = Target ?? _element;
			var bounds = t.ActualSize;
			var progress = (_currentCoord - _startCoord) / bounds;
			Progress = Math.Clamp(_startProgress + PrimaryValue(progress), 0.0, 1.0);
		}	
		
		float PrimaryValue(float2 v)
		{
			switch (Edge)
			{
				case Edge.Left: return v.X;
				case Edge.Right: return -v.X;
				case Edge.Top: return v.Y;
				case Edge.Bottom: return -v.Y;
			}
			return 0;
		}
	}
}