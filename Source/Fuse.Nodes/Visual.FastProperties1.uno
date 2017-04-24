
namespace Fuse
{
	internal enum FastProperty1
	{
		IsEnabled = 1<<0,
		IsContextEnabledCache = 1<<1,
		IsLocalFlat = 1<<2,
		IsLocalFlatCached = 1<<3,
		AreChildrenFlatCached = 1<<4,
		AreChildrenFlat = 1<<5,

		// Element
		MinWidth = 1<<6,
		MinHeight = 1<<7,
		MaxWidth = 1<<8,
		MaxHeight = 1<<9,

		Margin = 1<<10,
		Padding = 1<<11,
		Anchor = 1<<12,
		Offset = 1<<13,
		X = 1<<14,
		Y = 1<<15,

		Aspect = 1<<16,
		AspectConstraint = 1<<17,

		CachingMode = 1<<18,
		HitTestMode = 1<<19,
		ClipToBounds = 1<<20,
		TransformOrigin = 1<<21,

		Opacity = 1<<22,

		LimitWidth = 1<<23,
		LimitHeight = 1<<24,

		SnapToPixels = 1<<25,
		ContextSnapToPixelsCache = 1<<26,
		HasSnapToPixels = 1<<27,

		PendingRemove = 1<<28
	}

	class FastProperty1Link
	{
		public readonly FastProperty1 Property;
		public FastProperty1Link Next;

		public FastProperty1Link(FastProperty1 p)
		{
			Property = p;
		}
	}

	class FastProperty1Link<T>: FastProperty1Link
	{
		public T Value;
		public FastProperty1Link(FastProperty1 p, T value) : base(p)
		{
			Value = value;
		}
	}


	public partial class Visual
	{
		FastProperty1Link _fastProperties1;
		int _fastPropertyBits1 = FastProperty1.IsEnabled | FastProperty1.IsContextEnabledCache | 
			FastProperty1.SnapToPixels | FastProperty1.ContextSnapToPixelsCache;

		internal T Get<T>(FastProperty1 p, T defaultValue)
		{
			if (HasBit(p)) return Find<T>(p).Value;
			else return defaultValue;
		}

		internal void Set<T>(FastProperty1 p, T value, T defaultValue)
		{
			if (HasBit(p))
			{
				if (object.Equals(value, defaultValue)) Clear(p);
				else Find<T>(p).Value = value;
			}
			else
			{
				if (!object.Equals(value, defaultValue)) Insert<T>(p, value);
			}
		}

		void Clear(FastProperty1 p)
		{
			if (HasBit(p))
			{
				var k = FindPrevious(p);
				if (k == null) _fastProperties1 = _fastProperties1.Next;
				else k.Next = k.Next.Next;
				ClearBit(p);
			}
		}

		internal bool HasBit(FastProperty1 p)
		{
			return (_fastPropertyBits1 & (int)p) != 0;
		}

		internal void ClearBit(FastProperty1 p)
		{
			_fastPropertyBits1 &= ~(int)p;
		}

		internal void SetBit(FastProperty1 p)
		{
			_fastPropertyBits1 |= (int)p;
		}

		internal void SetBit(FastProperty1 p, bool value)
		{
			if (value) SetBit(p);
			else ClearBit(p);
		}

		void Insert<T>(FastProperty1 p, T value)
		{
			var nl = new FastProperty1Link<T>(p, value);

			if (_fastProperties1 == null)
			{
				_fastProperties1 = nl;
			}
			else
			{
				var last = _fastProperties1;
				while (last.Next != null) last = last.Next;
				last.Next = nl;
			}

			SetBit(p);
		}

		FastProperty1Link FindPrevious(FastProperty1 p)
		{
			FastProperty1Link pr = null;
			var n = _fastProperties1;
			while (n != null)
			{
				if (n.Property == p) return pr;
				pr = n;
				n = n.Next;
			}
			return null;
		}

		FastProperty1Link<T> Find<T>(FastProperty1 p)
		{
			var n = _fastProperties1;
			while (n != null)
			{
				if (n.Property == p) return (FastProperty1Link<T>)n;
				n = n.Next;
			}
			return null;
		}


	}

}
