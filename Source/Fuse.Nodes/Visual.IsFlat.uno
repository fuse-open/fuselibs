using Uno;

namespace Fuse
{
	/*
		Our definition of flat is that an entity resides entirely on the XY plane (Z=0). This is
		more strict than a generic definition of flatness, but useful for our optimizations.
	*/
	public abstract partial class Visual
	{
		internal void InvalidateFlat()
		{
			if (_isLocalFlatCached || _areChildrenFlatCached)
			{
				_isLocalFlatCached = false;
				_areChildrenFlatCached = false;
				if (Parent != null)
					Parent.InvalidateFlat();
			}
		}
		
		bool _isLocalFlatCached 
		{
			get { return HasBit(FastProperty1.IsLocalFlatCached); }
			set { SetBit(FastProperty1.IsLocalFlatCached, value); }
		}
		bool _isLocalFlat
		{
			get { return HasBit(FastProperty1.IsLocalFlat); }
			set { SetBit(FastProperty1.IsLocalFlat, value);}
		}

		//refers to local transform on the element
		internal bool IsLocalFlat
		{
			get
			{
				if (_isLocalFlatCached)
					return _isLocalFlat;
					
				_isLocalFlat = CalcIsLocalFlat();
				_isLocalFlatCached = true;
				return _isLocalFlat;
			}
		}
		
		internal virtual bool CalcIsLocalFlat()
		{
			for (var t = FirstChild<Transform>(); t != null; t = t.NextSibling<Transform>())
				if (!t.IsFlat) return false;

			return true;
		}
		
		bool _areChildrenFlatCached
		{
			get { return HasBit(FastProperty1.AreChildrenFlatCached); }
			set { SetBit(FastProperty1.AreChildrenFlatCached, value); }
		}

		bool _areChildrenFlat
		{
			get { return HasBit(FastProperty1.AreChildrenFlat); }
			set { SetBit(FastProperty1.AreChildrenFlat, value); }
		}

		//refers strictly to children of the element
		internal bool AreChildrenFlat
		{
			get
			{
				if (_areChildrenFlatCached)
					return _areChildrenFlat;
				
				_areChildrenFlat = CalcAreChildrenFlat();
				_areChildrenFlatCached = true;
				return _areChildrenFlat;
			}
		}
		
		internal virtual bool CalcAreChildrenFlat()
		{
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (!v.AreChildrenFlat || !v.IsLocalFlat)
					return false;
			
			return true;
		}
		
		//Compeltely flat, both locally and children
		internal bool IsFlat { get { return IsLocalFlat && AreChildrenFlat; } }
	}
}