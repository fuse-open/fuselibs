using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Triggers;
using Fuse.Internal;

namespace Fuse.Gestures.Internal
{
	delegate void TwoFingerEventHandler();
	delegate void TwoFingerZoomHandler(float factor);
	delegate void TwoFingerRotateHandler(float angle);
	delegate void TwoFingerTranslateHandler(float2 amount);
	
	sealed class TwoFinger : IGesture
	{
		float _keyZoomRangeUp = 200;
		float _keyZoomRangeDown = 100;
		float _startThresholdDistance = 20;
		
		int _attachCount = 1;
		Visual _node;
		
		TwoFinger(Visual n)
		{
			_node = n;
		}

		bool _allowKeyControl = true;
		
		static readonly PropertyHandle _property = Fuse.Properties.CreateHandle();
		static public TwoFinger Attach(Visual n)
		{
			object v;
			if (n.Properties.TryGet(_property, out v))
			{
				var t = v as TwoFinger;
				t._attachCount++;
				return t;
			}

			var nt = new TwoFinger(n);
			n.Properties.Set(_property, nt);
			nt.OnRooted();
			return nt;
		}
		
		public void Detach()
		{
			_attachCount--;
			if (_attachCount == 0)
			{
				OnUnrooted();
				_node.Properties.Clear(_property);
			}
		}
		
		Gesture _gesture;
		void OnRooted()
		{
			_gesture = Input.Gestures.Add( this, _node, GestureType.Multi );
		}
		
		void OnUnrooted()
		{
			_gesture.Dispose();
			_gesture = null;
		}

		public event TwoFingerEventHandler Started;
		public event TwoFingerEventHandler Ended;
		public event TwoFingerZoomHandler Zoomed;
		public event TwoFingerRotateHandler Rotated;
		public event TwoFingerTranslateHandler Translated;
		
		void IGesture.OnLostCapture(bool forced)
		{
			_point[0].Down = _point[1].Down = -1;
			_trackingKeyboard = false;
			if (_begun)
			{
				_begun = false;
				if (Ended != null)
					Ended();
			}
		}
		
		class Point
		{
			public int Down = -1;
			public float2 Start, Current, Previous;
		}
		Point[] _point = new[]{ new Point(), new Point() };
		float2 _fullTrans;
		bool _trackingKeyboard;
	
		GestureRequest IGesture.OnPointerPressed(PointerPressedArgs args)
		{
			if (_point[1].Down != -1)
				return GestureRequest.Ignore;
				
			return GestureRequest.Capture;
		}

		GesturePriorityConfig IGesture.Priority
		{
			get
			{
				float sig = 0;
				if (_trackingKeyboard)
					sig = Vector.Length( _point[0].Current - _point[0].Start );
				else if (_point[1].Down != -1)
					sig = Vector.Length( _point[0].Current - _point[0].Start ) +
					Vector.Length( _point[1].Current - _point[1].Start );
				return new GesturePriorityConfig( GesturePriority.Normal, sig );
			}
		}
		
		bool _begun;
		void IGesture.OnCaptureChanged( PointerEventArgs args, CaptureType type, CaptureType prev )
		{
			var p = PointFromArgs(args);
			if (p == null)
				p = _point[0].Down == -1 ? _point[0] : _point[1];
				
			if (p.Down == -1)
			{
				p.Start = p.Current = p.Previous = FromWindow(args.WindowPoint);
				p.Down = args.PointIndex;
			
				//alwas reset start
				_point[0].Start = _point[0].Previous = _point[0].Current;
				_fullTrans = float2(0);
			}
			
			if (CaptureTypeHelper.BecameHard(prev,type))
			{
				_begun = true;
			
				_point[0].Start = _point[0].Current;
				_point[1].Start = _point[1].Current;
				_fullTrans = float2(0);
			
				if (Started != null)
					Started();
			}
		}
		
		float2 FromWindow(float2 p)
		{
			if(_node.Parent == null)
				return p;
			//use parent on the assumption that element itself might be moving/transforming
			return _node.Parent.WindowToLocal(p);
		}
		
		Point PointFromArgs(PointerEventArgs args)
		{	
			if (args.PointIndex == _point[0].Down)
				return _point[0];
			if (args.PointIndex == _point[1].Down)
				return _point[1];
			return null;
		}
		
		GestureRequest IGesture.OnPointerMoved(PointerMovedArgs args)
		{
			var p = PointFromArgs(args);
			if (p == null)
				return GestureRequest.Cancel;
				
			p.Current = FromWindow(args.WindowPoint);

			float scale = 1;
			float angle = 0;
			float2 trans = float2(0);
			
			// float hardDist = 0;
			if (_point[1].Down != -1)
			{
				var start = _point[0].Start - _point[1].Start;
				var current = _point[0].Current - _point[1].Current;
				scale = Vector.Length(current) / Vector.Length(start);
				
				var sa = Math.Atan2(start.Y,start.X);
				var ea = Math.Atan2(current.Y,current.X);
				angle = ea - sa;

				var startCenter = (_point[0].Start - _point[1].Start)/2 + _point[1].Start;
				var currentCenter = (_point[0].Current - _point[1].Current)/2 + _point[1].Current;
				var rawTrans = currentCenter - startCenter;
	
				var rot = Matrix.RotationZ(-angle);
				trans = Vector.Transform(rawTrans, rot).XY / scale;
				
				/*if (_begun)
				{
					_point[0].Previous = _point[0].Current;
					_point[1].Previous = _point[1].Current;
				}*/
				
			}
			else if (_allowKeyControl)
			{
				if (Keyboard.IsKeyPressed(Uno.Platform.Key.ControlKey))
				{
					var diff = p.Current.Y - p.Start.Y;
					scale = diff < 0 ? (-diff / _keyZoomRangeUp + 1) : 
						(_keyZoomRangeDown / (_keyZoomRangeDown+diff));
					// hardDist = Math.Abs(diff);
					
					var l = p.Current - p.Start;
					if (Math.Abs(l.X) + Math.Abs(l.Y) > 10)
						angle = Math.Atan2(diff < 0 ? l.Y : -l.Y, diff < 0 ? l.X : -l.X) + Math.PIf/2;
						
					_trackingKeyboard = true;
				}
				else if (Keyboard.IsKeyPressed(Uno.Platform.Key.ShiftKey))
				{
					trans = _point[0].Current - _point[0].Start;
					// hardDist = Vector.Length(trans);
					_trackingKeyboard = true;
				}
			}
			
			if (_begun)
			{
				if (Zoomed != null)
					Zoomed(scale);
				if (Rotated != null)
					Rotated(angle);
				if (Translated != null)
					Translated(trans);
			}
			
			return GestureRequest.Capture;
		}
		
		GestureRequest IGesture.OnPointerReleased(PointerReleasedArgs args)
		{
			return GestureRequest.Cancel;
		}
	}
	
}
