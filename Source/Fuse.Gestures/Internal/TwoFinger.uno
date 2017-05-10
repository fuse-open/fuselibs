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
	
	sealed class TwoFinger
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
		
		void OnRooted()
		{
			Pointer.Pressed.AddHandler(_node, OnPointerPressed);
			Pointer.Released.AddHandler(_node, OnPointerReleased);
			Pointer.Moved.AddHandler(_node, OnPointerMoved);
		}
		
		void OnUnrooted()
		{
			Pointer.Pressed.RemoveHandler(_node, OnPointerPressed);
			Pointer.Released.RemoveHandler(_node, OnPointerReleased);
			Pointer.Moved.RemoveHandler(_node, OnPointerMoved);
		}

		public event TwoFingerEventHandler Started;
		public event TwoFingerEventHandler Ended;
		public event TwoFingerZoomHandler Zoomed;
		public event TwoFingerRotateHandler Rotated;
		public event TwoFingerTranslateHandler Translated;
		
		void OnLostCapture()
		{
			_point[0].Down = _point[1].Down = -1;
			Pointer.ReleaseCapture(this);
			if (_begun)
			{
				_node.EndInteraction(this);
				if (Ended != null)
					Ended();
			}
			_begun = false;
		}
		
		class Point
		{
			public int Down = -1;
			public float2 Start, Current, Previous;
		}
		Point[] _point = new[]{ new Point(), new Point() };
		float2 _fullTrans;
	
		void OnPointerPressed(object sender, PointerPressedArgs args)
		{
			if (_point[1].Down != -1)
				return;
			
			if ( ((_point[0].Down == -1) && 
				!Pointer.ModifyCapture(this, _node, OnLostCapture, CaptureType.Soft, args.PointIndex)) ||
				!Pointer.ExtendCapture(this, args.PointIndex) )
			{
				OnLostCapture();
				return;
			}
			
			
			Point p = _point[0].Down == -1 ? _point[0] : _point[1];
			p.Start = p.Current = p.Previous = FromWindow(args.WindowPoint);
			p.Down = args.PointIndex;
			
			//alwas reset start
			_point[0].Start = _point[0].Previous = _point[0].Current;
			_fullTrans = float2(0);
		}
		
		bool _begun;
		void Begin()
		{
			if (!Pointer.ModifyCapture(this, CaptureType.Hard))
			{
				OnLostCapture();
				return;
			}
			
			_begun = true;
			_node.BeginInteraction(this, OnLostCapture);
			
			_point[0].Start = _point[0].Current;
			_point[1].Start = _point[1].Current;
			_fullTrans = float2(0);
			
			if (Started != null)
				Started();
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
		
		void OnPointerMoved(object sender, PointerMovedArgs args)
		{
			var p = PointFromArgs(args);
			if (p == null)
				return;
				
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
				}
				else if (Keyboard.IsKeyPressed(Uno.Platform.Key.ShiftKey))
				{
					trans = _point[0].Current - _point[0].Start;
					// hardDist = Vector.Length(trans);
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
			else //if (hardDist > _startThresholdDistance) TODO:!!
			{
				Begin();
			}
		}
		
		void OnPointerReleased(object sender, PointerReleasedArgs args)
		{
			if (args.PointIndex == _point[0].Down || args.PointIndex == _point[1].Down)
			{
				OnLostCapture();
			}
		}
	}
	
}
