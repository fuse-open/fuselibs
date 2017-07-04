using Uno;
using Uno.Collections;

namespace Fuse
{
	/*
		Our definition of flat is that an entity resides entirely on the XY plane (Z=0). This is
		more strict than a generic definition of flatness, but useful for our optimizations.
	*/
	public abstract partial class Visual
	{
		// To be overridden to do nothing by flattening nodes (i.e. Viewport)
		internal virtual void ParentIncrementNonFlat()
		{
			IncrementNonFlat();
		}

		// To be overridden to do nothing by flattening nodes (i.e. Viewport)
		internal virtual void ParentDecrementNonFlat()
		{
			DecrementNonFlat();
		}

		int _nonFlat = 0;
		internal virtual void IncrementNonFlat()
		{
			_nonFlat++;
			if (Parent != null) Parent.ParentIncrementNonFlat();
		}
		internal virtual void DecrementNonFlat()
		{
			_nonFlat--;
			if (Parent != null) Parent.ParentDecrementNonFlat();
		}

		int _localNonFlat = 0;
		internal void IncrementLocalNonFlat()
		{
			_localNonFlat++;
			if (_flatRooted && _localNonFlat == 1)
				IncrementNonFlat();
		}

		internal void DecrementLocalNonFlat()
		{
			_localNonFlat--;
			if (_flatRooted && _localNonFlat == 0)
				DecrementNonFlat();
		}

		bool _flatRooted;
		void FlatRooted()
		{
			if (_nonFlat != 0)
				throw new Exception(); // Should never happen

			if (_localNonFlat > 0)
				IncrementNonFlat();
			
			_flatRooted = true;
		}

		void FlatUnrooted()
		{
			if (_localNonFlat > 0)
				DecrementNonFlat();

			_flatRooted = false;

			if (_nonFlat != 0)
				throw new Exception(); // Should never happen
		}

		//refers to local transform on the element
		internal bool IsLocalFlat
		{
			get { return _localNonFlat == 0; }
		}

		// Compeltely flat, both locally and children
		internal bool IsFlat { get { return _nonFlat == 0; } }
	}
}