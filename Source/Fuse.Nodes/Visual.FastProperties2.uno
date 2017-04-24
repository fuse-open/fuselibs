
namespace Fuse
{
	internal enum FastProperty2
	{
		Color = 1<<0,

		// TextControl
		TextWrapping = 1<<1,
		IsMultiline = 1<<2,
		InputHint = 1<<3,
		PlaceholderText = 1<<4,
		PlaceholderColor = 1<<5,
		ActionStyle = 1<<6,
		CaretColor = 1<<7,
		SelectionColor = 1<<8,
		LineSpacing = 1<<9,
		TextAlignment = 1<<10,
		TextTruncation = 1<<11,
		IsPassword = 1<<12,
		IsReadOnly = 1<<13,
		AutoCorrectHint = 1<<14,
		AutoCapitalizationHint = 1<<15
	}

	class FastProperty2Link
	{
		public readonly FastProperty2 Property;
		public FastProperty2Link Next;

		public FastProperty2Link(FastProperty2 p)
		{
			Property = p;
		}
	}

	class FastProperty2Link<T>: FastProperty2Link
	{
		public T Value;
		public FastProperty2Link(FastProperty2 p, T value) : base(p) 
		{
			Value = value;
		}
	}


	public partial class Visual
	{
		FastProperty2Link _fastProperties2;
		int _fastPropertyBits2;

		internal T Get<T>(FastProperty2 p, T defaultValue)
		{
			if (HasBit(p)) return Find<T>(p).Value;
			else return defaultValue;
		}

		internal void Set<T>(FastProperty2 p, T value, T defaultValue)
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

		void Clear(FastProperty2 p)
		{
			if (HasBit(p))
			{
				var k = FindPrevious(p);
				if (k == null) _fastProperties2 = _fastProperties2.Next;
				else k.Next = k.Next.Next;
				ClearBit(p);
			}
		}

		internal bool HasBit(FastProperty2 p)
		{
			return (_fastPropertyBits2 & (int)p) != 0;
		}

		internal void ClearBit(FastProperty2 p)
		{
			_fastPropertyBits2 ^= (int)p;
		}

		internal void SetBit(FastProperty2 p)
		{
			_fastPropertyBits2 |= (int)p;
		}

		internal void SetBit(FastProperty2 p, bool value)
		{
			if (value) SetBit(p);
			else ClearBit(p);
		}

		void Insert<T>(FastProperty2 p, T value)
		{
			var nl = new FastProperty2Link<T>(p, value);

			if (_fastProperties2 == null)
			{
				_fastProperties2 = nl;
			}
			else
			{
				var last = _fastProperties2;
				while (last.Next != null) last = last.Next;
				last.Next = nl;
			}

			SetBit(p);
		}

		FastProperty2Link FindPrevious(FastProperty2 p)
		{
			FastProperty2Link pr = null;
			var n = _fastProperties2;
			while (n != null)
			{
				if (n.Property == p) return pr;
				pr = n;
				n = n.Next;
			}
			return null;
		}

		FastProperty2Link<T> Find<T>(FastProperty2 p)
		{
			var n = _fastProperties2;
			while (n != null)
			{
				if (n.Property == p) return (FastProperty2Link<T>)n;
				n = n.Next;
			}
			return null;
		}

		
	}

}