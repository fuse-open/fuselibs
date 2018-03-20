using Uno;
using Uno.UX;

namespace Fuse.Drawing
{
	public enum StrokeAdjustment
	{
		None,
		PixelCeil,
		PixelNear,
		PixelFloor,
	}

	public enum StrokeAlignment
	{
		Center,
		Inside,
		Outside,
	}

	public class Stroke: PropertyObject, IPropertyListener
	{
		//https://github.com/fusetools/fuselibs-private/issues/3655
		static Selector _shadingName = "Shading";
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == Brush)
				OnPropertyChanged(_shadingName);
		}

		static Selector _brushName = "Brush";
		Brush _brush;
		[UXContent]
		public Brush Brush
		{
			get { return _brush; }
			set
			{
				if (value == _brush) 
					return;
					
				if (IsPinned && _brush != null)
					_brush.Unpin();
					
				if (IsPinned && _brush is DynamicBrush) 
					((DynamicBrush)_brush).RemovePropertyListener(this);
				_brush = value;
				if (IsPinned && _brush is DynamicBrush) 
					((DynamicBrush)_brush).AddPropertyListener(this);
				
				if (IsPinned && _brush != null)
					_brush.Pin();
				
				OnPropertyChanged(_brushName);
			}
		}

		static Selector _colorName = "Color";
		[UXOriginSetter("SetColor")]
		/**
			The color of the stroke.

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get
			{
				if (Brush is ISolidColor)
					return ((ISolidColor)Brush).Color;
				return float4(0);
			}
			set
			{	
				SetColor(value, this);
			}
		}
		public void SetColor(float4 color, IPropertyListener origin)
		{
			if (color != Color)
			{
				if (!(Brush is SolidColor))
 					Brush = new SolidColor(color);
	 			else
	 				((SolidColor)Brush).Color = color;

	 			OnPropertyChanged(_colorName, origin);
			}
		}

		static Selector _widthName = "Width";
		float _width = 1.0f;
		public float Width
		{
			get { return _width; }
			set
			{
				_width = value;
				OnPropertyChanged(_widthName);
			}
		}

		static Selector _offsetName = "Offset";
		float _offset = 0.0f;
		public float Offset
		{
			get { return _offset; }
			set
			{
				_offset = value;
				OnPropertyChanged(_offsetName);
			}
		}
		
		static Selector _adjustmentName = "Adjustment";
		StrokeAdjustment _adjustment = StrokeAdjustment.PixelNear;
		public StrokeAdjustment Adjustment
		{
			get { return _adjustment; }
			set 
			{
				if (_adjustment != value)
				{
					_adjustment = value;
					OnPropertyChanged(_adjustmentName);
				}
			}
		}
		
		static Selector _alignmentName = "Alignment";
		StrokeAlignment _alignment = StrokeAlignment.Inside;
		public StrokeAlignment Alignment
		{
			get { return _alignment; }
			set
			{
				if (_alignment != value)
				{
					_alignment = value;
					OnPropertyChanged(_alignmentName);
				}
			}
		}
		

		/**
			Combines the Width, Alignment, and Offset to get the logical extents of the stroke.
			
			@return float2(width, center)
		*/
		public float2 GetDeviceAdjusted( float pixelsPerPoint )
		{
			var ppi = pixelsPerPoint;
			float lo =0, hi = 0;
			switch( Alignment )
			{
				case StrokeAlignment.Outside:
					lo = Math.Ceil( (_offset - 0.5f)*ppi ) / ppi;
					hi = lo + Adjust( _width, ppi );
					break;

				case StrokeAlignment.Inside:
					hi = Math.Floor( (_offset + 0.5f)*ppi ) / ppi;
					lo = hi - Adjust( _width, ppi );
					break;

				case StrokeAlignment.Center:
					lo = AdjustPosition(_offset - _width/2, ppi);
					hi = lo + Adjust( _width, ppi );
					break;
			}

			var r = float2(hi-lo,(hi+lo)/2);
			return r;
		}

		float AdjustPosition(float w, float ppi)
		{
			switch( Adjustment )
			{
				case StrokeAdjustment.None:
					return w;

				case StrokeAdjustment.PixelCeil:
					w = Math.Ceil( w * ppi ) / ppi;
					break;

				case StrokeAdjustment.PixelNear:
					w = Math.Floor( w * ppi + 0.5f ) / ppi;
					break;

				case StrokeAdjustment.PixelFloor:
					w = Math.Floor( w * ppi ) / ppi;
					break;
			}
			
			return w;
		}
		
		float Adjust(float w, float ppi)
		{
			w = AdjustPosition(w,ppi);
			//set minimum 1-pixel wide stroke
			w = Math.Max( w, 1/ppi );
			return w;
		}

		static Selector _lineCapName = "LineCap";
		LineCap _lineCap = Fuse.Drawing.LineCap.Butt;
		public LineCap LineCap
		{
			get { return _lineCap; }
			set
			{
				if (value == _lineCap) return;
				_lineCap = value;
				OnPropertyChanged(_lineCapName);
			}
		}

		static Selector _lineJoinName = "LineJoin";
		LineJoin _lineJoin = Fuse.Drawing.LineJoin.Miter;
		public LineJoin LineJoin
		{
			get { return _lineJoin; }
			set
			{
				if (value == _lineJoin) return;
				_lineJoin = value;
				OnPropertyChanged(_lineJoinName);
			}
		}
		
		static Selector _lineJoinMiterLimitName = "LineJoinMiterLimit";
		float _lineJoinMiterLimit = 1;
		/**
			Clips miter joins at this limit. 
			
			This value is relative to the stroke width.
		*/
		public float LineJoinMiterLimit
		{
			get { return _lineJoinMiterLimit; }
			set
			{
				if (value == _lineJoinMiterLimit) return;
				_lineJoinMiterLimit = value;
				OnPropertyChanged(_lineJoinMiterLimitName);
			}
		}

		public Stroke() { }
		
		public Stroke(Brush brush, float width = 1.0f, LineCap lineCap = Fuse.Drawing.LineCap.Butt, LineJoin lineJoin = Fuse.Drawing.LineJoin.Miter)
		{
			Brush = brush;
			Width = width;
			LineCap = lineCap;
			LineJoin = lineJoin;
		}
		
		int _pinCount;
		public void Pin()
		{
			_pinCount++;
			if (_pinCount == 1)
				OnPinned();
		}
		
		public void Unpin()
		{
			_pinCount--;
			if (_pinCount == 0)
				OnUnpinned();
		}
		
		public bool IsPinned { get { return _pinCount > 0; } }
		
		protected void OnPinned() 
		{ 
			if (Brush != null)
			{
				Brush.Pin();
				var db = Brush as DynamicBrush;
				if (db != null)
					db.AddPropertyListener(this);
			}
		}
		
		protected void OnUnpinned() 
		{ 
			if (Brush != null)
			{
				Brush.Unpin();
				var db = Brush as DynamicBrush;
				if (db != null)
					db.RemovePropertyListener(this);
			}
		}

		public void Prepare(DrawContext dc, float2 canvasSize)
		{
			if (Brush != null)
				Brush.Prepare(dc, canvasSize);
		}
	}
}
