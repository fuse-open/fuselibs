using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public partial class Visual
	{
		float _zOffset = 0;
		/**
			Specifics a ZOffset, higher values are in front of other nodes. Only used by certain Node's,
			such as `Panel`. The ZLayer has priority, then ZOffset, then ZOffsetNatural.
		*/
		public float ZOffset
		{
			get { return _zOffset; }
			set
			{
				if (_zOffset == value)
					return;
				_zOffset = value;
				if (Parent != null)	
					Parent.InvalidateZOrder();
			}
		}

		Visual[] _cachedZOrder;
		internal Visual[] GetCachedZOrder()
		{
			if (_cachedZOrder == null)
					_cachedZOrder = ComputeZOrder();
				
			return _cachedZOrder;
		}

		int _naturalZOrder;

		/** Brings the given child to the front of the Z-order. 
			In UX markup, use the @BringToFront trigger action instead.
		*/
		public void BringToFront(Visual item)
		{
			var maxNaturalZOrder = int.MinValue;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (v != item && v._naturalZOrder > maxNaturalZOrder) 
					maxNaturalZOrder = v._naturalZOrder;
			
			if (maxNaturalZOrder != int.MinValue && maxNaturalZOrder+1 != _naturalZOrder)
			{
				_naturalZOrder = maxNaturalZOrder+1;
				InvalidateZOrder();
			}
		}

		/** Sends the given child to the back of the Z-order. 
			In UX markup, use the @SendToBack trigger action instead.
		*/
		public void SendToBack(Visual item)
		{
			var minNaturalZOrder = int.MaxValue;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (v != item && v._naturalZOrder < minNaturalZOrder) minNaturalZOrder = v._naturalZOrder;
			
			if (minNaturalZOrder != int.MaxValue && minNaturalZOrder-1 != _naturalZOrder)
			{
				_naturalZOrder = minNaturalZOrder-1;
				InvalidateZOrder();
			}
		}

		protected virtual void OnZOrderInvalidated() {}
	
		void InvalidateZOrder()
		{
			_cachedZOrder = null;
			OnZOrderInvalidated();
		}

		static Visual[] _emptyVisuals = new Visual[0];

		Visual[] ComputeZOrder()
		{
			if (_visualChildCount == 0) return _emptyVisuals;
			if (_visualChildCount == 1) return new Visual[1] { FirstChild<Visual>() };

			var zOrder = new Visual[_visualChildCount];

			bool needsSorting = false;
			Layer layer = Layer.Underlay;
			bool hasLayer = false;
			int i = 0;
			for (var v = LastChild<Visual>(); v != null; v = v.PreviousSibling<Visual>(), i++)
			{
				zOrder[i] = v;
				if (v.ZOffset != 0) needsSorting = true;
				if (!hasLayer) { layer = v.Layer; hasLayer = true; }
				else if (v.Layer != layer) needsSorting = true;
			}

			if (needsSorting)
				Array.Sort(zOrder, ZOrderComparator);

			return zOrder;
		}

		static int ZOrderComparator(Visual a, Visual b)
		{
			if (a.Layer != b.Layer)
				return (int)a.Layer - (int)b.Layer;
			//to preserve ordering through interpolation we're forced to do exact match here. This is
			//also okay, since things that need exact match will just use integer values
			if (a.ZOffset != b.ZOffset)
				return a.ZOffset > b.ZOffset ? 1 : -1;
			return a._naturalZOrder - b._naturalZOrder;
		}
	}
}
