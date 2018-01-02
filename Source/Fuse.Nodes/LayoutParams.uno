using Uno;

namespace Fuse
{
	/**
		If a size parameter is not availble it will reutrn 0, via Size, X, Y
		
		`struct` was chosen here over `class` for performance reasons. A lot of these objects are
		created for node in the tree and in performance testing the structs were simply performing
		a lot better.
	*/
	public struct LayoutParams
	{
		enum Flags
		{
			None = 0,
			X = 1<<0,
			Y = 1<<1,
			Temporary = 1<<2,
			MaxX = 1<<3,
			MaxY = 1<<4,
			MinX = 1<<5,
			MinY = 1<<6,
			RelativeX = 1<<7,
			RelativeY = 1<<8,
			NoRelativeX = 1<<9,
			NoRelativeY = 1<<10,
		}
		Flags _flags;
		
		float2 _size;
		float2 _maxSize;
		float2 _minSize;
		float2 _relativeSize;

		void SetFlag( Flags g, bool val )
		{
			if (val)
				_flags |= g;
			else
				_flags &= ~g;
		}
		
		public bool HasX { get { return _flags.HasFlag(Flags.X); } }
		public bool HasY { get { return _flags.HasFlag(Flags.Y); } }
		public bool HasSize { get { return HasX && HasY; } }
		
		public bool Temporary { get { return _flags.HasFlag(Flags.Temporary); } }
		
		public bool HasMaxX { get { return _flags.HasFlag(Flags.MaxX); } }
		public bool HasMaxY { get { return _flags.HasFlag(Flags.MaxY); } }
		public bool HasMaxSize { get { return HasMaxX && HasMaxY; } }
		
		public bool HasMinX { get { return _flags.HasFlag(Flags.MinX); } }
		public bool HasMinY { get { return _flags.HasFlag(Flags.MinY); } }
		public bool HasMinSize { get { return HasMinX && HasMinY; } }
		
		public bool HasRelativeX
		{	
			get
			{
				if (_flags.HasFlag(Flags.NoRelativeX))
					return false;
				return _flags.HasFlag(Flags.RelativeX) || HasX;
			}
		}
		public bool HasRelativeY
		{	
			get
			{
				if (_flags.HasFlag(Flags.NoRelativeY))
					return false;
				return _flags.HasFlag(Flags.RelativeY) || HasY;
			}
		}
		
		/**
			Create an exact copy of this instance.
		*/
		public LayoutParams Clone()
		{
			var lp = new LayoutParams();
			lp._flags = _flags;
			lp._size = _size;
			lp._maxSize = _maxSize;
			lp._minSize = _minSize;
			lp._relativeSize = _relativeSize;
			return lp;
		}
		
		static bool _warnTrueClone;
		/** @deprecated: use `Clone` */
		public LayoutParams TrueClone()
		{
			if (!_warnTrueClone)
			{
				//deprecated: 2016-09-05
				Fuse.Diagnostics.Deprecated( "Use Clone instead of TrueClone", this );
				_warnTrueClone = true;
			}
			return Clone();
		}
		
		/**
			Create a copy of this instance that is suitable for used in layout derivation.
			
			This clears the relative settings on the layout.
		*/
		public LayoutParams CloneAndDerive()
		{
			var lp = Clone();
			lp.SetFlag(Flags.RelativeX, false);
			lp.SetFlag(Flags.RelativeY, false);
			lp.SetFlag(Flags.NoRelativeX, false);
			lp.SetFlag(Flags.NoRelativeY, false);
			lp._relativeSize = float2(0);
			return lp;
		}
		
		static bool _warnDeriveClone;
		/** @deprecated: use `CloneAndDerive` */
		public LayoutParams DeriveClone()
		{
			if (!_warnDeriveClone)
			{
				//deprecated: 2016-09-05
				Fuse.Diagnostics.Deprecated( "Use CloneAndDerive instead of DeriveClone", this );
				_warnDeriveClone = true;
			}
			return CloneAndDerive();
		}
		
		public void Reset()
		{
			_flags = Flags.None;
			_size = _maxSize = _minSize = _relativeSize = float2(0);
		}
		
		public void Copy(LayoutParams o)
		{
			_flags = o._flags;
			_size = o._size;
			_maxSize = o._maxSize;
			_minSize = o._minSize;
			_relativeSize = o._relativeSize;
		}
		
		static public LayoutParams Create( float2 size )
		{
			var lp = new LayoutParams();
			lp.SetFlag(Flags.X, true);
			lp.SetFlag(Flags.Y, true);
			lp._size = Math.Max(float2(0), size);
			return lp;
		}
		
		static public LayoutParams CreateTemporary( float2 size )
		{
			var lp = new LayoutParams();
			lp.SetFlag(Flags.X,true);
			lp.SetFlag(Flags.Y,true);
			lp._size = Math.Max(float2(0), size);
			lp.SetFlag(Flags.Temporary, true);
			return lp;
		}
		
		static public LayoutParams CreateXY( float2 size, bool hasX, bool hasY )
		{
			var lp = new LayoutParams();
			lp.SetFlag(Flags.X,hasX);
			lp.SetFlag(Flags.Y,hasY);
			lp._size.X = hasX ? Math.Max(size.X,0) : 0;
			lp._size.Y = hasY ? Math.Max(size.Y,0) : 0;
			return lp;
		}
		
		static public LayoutParams CreateEmpty()
		{
			return new LayoutParams();
		}
		
		/**
			For removing border areas like Margin and Padding
		*/
		public void RemoveSize( float2 size )
		{
			_size = Math.Max(float2(0), _size - size);
			_maxSize = Math.Max(float2(0), _maxSize - size);
			_minSize = Math.Max(float2(0), _minSize - size);
		}
		
		public void RemoveSize( float4 size )
		{
			RemoveSize( size.XY + size.ZW );
		}
		
		public void RetainAxesXY( bool x, bool y )
		{
			RetainXY(x,y);
			RetainMaxXY(x,y);
		}
		
		/**
			Retains or discards the X/Y information.
			
			Be careful when using this, it is typically used in combination with RetainMaxXY (or RetainAxesXY in combination), or with a ConstrainMax. The layout must consider how it affects not just the X/Y values, but also the Min/Max XY values.
		*/
		public void RetainXY( bool x, bool y )
		{
			if (!x)
			{
				_size.X = 0;
				SetFlag(Flags.X,false);
			}
			if (!y)
			{
				_size.Y = 0;
				SetFlag(Flags.Y,false);
			}
		}
		
		public void RetainMaxXY( bool x, bool y )
		{
			if (!x)
			{
				_maxSize.X = 0;
				SetFlag(Flags.MaxX,false);
			}
			if (!y)
			{
				_maxSize.Y = 0;
				SetFlag(Flags.MaxY,false);
			}
		}
		
		public void SetSize( float2 xy, bool hasX = true, bool hasY = true )
		{
			_size = Math.Max(float2(0),xy);
			SetFlag(Flags.X,hasX);
			if (!hasX)
				_size.X = 0;
			SetFlag(Flags.Y,hasY);
			if (!hasY)
				_size.Y = 0;
		}
		
		public void SetX( float x )
		{
			SetFlag(Flags.X,true);
			_size.X = Math.Max(x,0);
		}

		public void SetY( float y )
		{
			SetFlag(Flags.Y, true);
			_size.Y = Math.Max(y,0);
		}
		
		public void SetRelativeSize(float2 sz, bool hasX, bool hasY)
		{
			_relativeSize = Math.Max(float2(0),sz);
			SetFlag(Flags.RelativeX,hasX);
			SetFlag(Flags.NoRelativeX,!hasX);
			SetFlag(Flags.RelativeY,hasY);
			SetFlag(Flags.NoRelativeY,!hasY);
		}

		public void ConstrainMaxX( float max )
		{
			if (HasMaxX)
				_maxSize.X = Math.Min(_maxSize.X,max);
			else
				_maxSize.X = max;
			SetFlag(Flags.MaxX,true);
		}
		
		public void ConstrainMaxY( float max )
		{
			if (HasMaxY)
				_maxSize.Y = Math.Min(_maxSize.Y,max);
			else
				_maxSize.Y = max;
			SetFlag(Flags.MaxY,true);
		}
		
		public void ConstrainMax( float2 max, bool hasMaxX = true, bool hasMaxY = true )
		{
			max = Math.Max(float2(0),max);
			
			if (hasMaxX)
				ConstrainMaxX(max.X);
			
			if (hasMaxY)
				ConstrainMaxY(max.Y);
		}

		public void ConstrainMinX( float min )
		{
			if (HasMinX)
				_minSize.X = Math.Max(_minSize.X,min);
			else
				_minSize.X = min;
			SetFlag(Flags.MinX,true);
		}
		
		public void ConstrainMinY( float min )
		{
			if (HasMinY)
				_minSize.Y = Math.Max(_minSize.Y,min);
			else
				_minSize.Y = min;
			SetFlag(Flags.MinY,true);
		}
		
		public void ConstrainMin( float2 min, bool hasMinX = true, bool hasMinY = true )
		{
			min = Math.Max(float2(0),min);
			
			if (hasMinX)
				ConstrainMinX(min.X);
			
			if (hasMinY)
				ConstrainMinY(min.Y);
		}
		
		/**
			Do box model constraining on this with the provided constraints.
		*/
		public void BoxConstrain( LayoutParams o )
		{
			SetSize(o.Size, o.HasX, o.HasY);
			ConstrainMax(o.MaxSize, o.HasMaxX, o.HasMaxY);
			ConstrainMin(o.MinSize, o.HasMinX, o.HasMinY);
		}
		
		/**
			Apply ordered constraints of this LayoutParams to the point.
		*/
		public float2 PointConstrain( float2 p )
		{
			var x = true;
			var y = true;
			return PointConstrain(p,ref x,ref y);
		}
		
		float2 PointConstrain( float2 p, ref bool knowX, ref bool knowY )
		{
			if (HasX)
			{
				p.X = X;
				knowX = true;
			}
			if (HasMaxX)
			{
				p.X = knowX ? Math.Min(p.X, MaxX) : MaxX;
				knowX = true;
			}
			if (HasMinX)
			{
				p.X = knowX ? Math.Max(p.X, MinX) : MinX;
				knowX = true;
			}
				
			if (HasY)
			{
				p.Y = Y;
				knowY = true;
			}
			if (HasMaxY)
			{
				p.Y = knowY ? Math.Min(p.Y, MaxY) : MaxY;
				knowY = true;
			}
			if (HasMinY)
			{
				p.Y = knowY ? Math.Max(p.Y, MinY) : MinY;
				knowY = true;
			}
			
			return p;
		}
		
		public float2 GetAvailableSize()
		{
			var x = false;
			var y = false;
			return PointConstrain(float2(0), ref x, ref y);
		}
		
		public float2 GetAvailableSize( out bool hasX, out bool hasY )
		{
			hasX = false;
			hasY = false;
			return PointConstrain(float2(0), ref hasX, ref hasY);
		}
		
		public float2 Size { get { return _size; } }
		public float X { get { return _size.X; } }
		public float Y { get { return _size.Y; } }
		
		public float2 MaxSize { get { return _maxSize; } }
		public float MaxX { get { return _maxSize.X; } }
		public float MaxY { get { return _maxSize.Y; } }
		
		public float2 MinSize { get { return _minSize; } }
		public float MinX { get { return _minSize.X; } }
		public float MinY { get { return _minSize.Y; } }

		public float2 RelativeSize { get { return float2(RelativeX, RelativeY); } }
		public float RelativeX 
		{ 
			get 
			{ 
				if (_flags.HasFlag(Flags.NoRelativeX))
					return 0;
				return _flags.HasFlag(Flags.RelativeX) ? _relativeSize.X : _size.X; 
			}
		}
		public float RelativeY 
		{ 
			get 
			{ 
				if (_flags.HasFlag(Flags.NoRelativeY))
					return 0;
				return _flags.HasFlag(Flags.RelativeY) ? _relativeSize.Y : _size.Y; 
			} 
		}
		
		//just for debugging
		internal string Format()
		{
			var s = "{Size=[";
			if (HasX)
				s += _size.X;
			else
				s += "*";
			s += ",";
			if (HasY)
				s += _size.Y;
			else
				s += "*";
			
			s += "] Max=[";
			if (HasMaxX)
				s += _maxSize.X;
			else
				s += "*";
			s += ",";
			if (HasMaxY)
				s += _maxSize.Y;
			else
				s += "*";
	
			s += "] Min=[";
			if (HasMinX)
				s += _minSize.X;
			else
				s += "*";
			s += ",";
			if (HasMinY)
				s += _minSize.Y;
			else
				s += "*";
				
			s += "] Rel=[";
			if (HasRelativeX)
				s += RelativeX;
			else
				s += "*";
			s += ",";
			if (HasRelativeY)
				s += RelativeY;
			else
				s += "*";
			s += "]}";
			return s;
		}
		
		public bool IsCompatible(LayoutParams nlp)
		{	
			if (HasX != nlp.HasX || HasY != nlp.HasY ||
				HasMaxX != nlp.HasMaxX || HasMaxY != nlp.HasMaxY ||
				HasMinX != nlp.HasMinX || HasMinY != nlp.HasMinY)
				return false;

			const float zeroTolerance = 1e-05f;
			if (HasX && (Math.Abs(X - nlp.X) > zeroTolerance))
				return false;
			if (HasY && (Math.Abs(Y - nlp.Y) > zeroTolerance))
				return false;
			if (HasMaxX && (Math.Abs(MaxX - nlp.MaxX) > zeroTolerance))
				return false;
			if (HasMinX && (Math.Abs(MinX - nlp.MinX) > zeroTolerance))
				return false;
			if (HasMaxY && (Math.Abs(MaxY - nlp.MaxY) > zeroTolerance))
				return false;
			if (HasMinY && (Math.Abs(MinY - nlp.MinY) > zeroTolerance))
				return false;
			if (HasRelativeX && (Math.Abs(RelativeX - nlp.RelativeX) > zeroTolerance))
				return false;
			if (HasRelativeY && (Math.Abs(RelativeY - nlp.RelativeY) > zeroTolerance))
				return false;
				
			return true;
		}
	}
}
