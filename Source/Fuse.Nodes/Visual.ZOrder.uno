using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public partial class Visual
	{
		float _zOffset = 0;
		/**
			Specifies a Z-Offset, visuals with higher values are in front of other visuals.

			The default value is `0`. Visuals with the same ZOffset are sorted by their natural
			Z-Order according to their position in the `Children`-collection of the parent.
			`BringToFront` and `SendToBack` can be used to modify the natural Z-Order.

			`Layer` takes priority. Visuals in different layers are sorted separately.
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
		bool _zOrderFixed;

		/** Brings the given child to the front of the Z-order. 
			In UX markup, use the @BringToFront trigger action instead.
		*/
		public void BringToFront(Visual item)
		{
			AssignNaturalZOrder(); // ensures _naturalZOrder is up to date

			var maxNaturalZOrder = int.MinValue;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (v != item && v.Layer == item.Layer && v._naturalZOrder > maxNaturalZOrder) 
					maxNaturalZOrder = v._naturalZOrder;
			
			if (maxNaturalZOrder != int.MinValue && maxNaturalZOrder+1 != item._naturalZOrder)
			{
				item._naturalZOrder = maxNaturalZOrder+1;
				item._zOrderFixed = true;
				InvalidateZOrder();
			}
		}

		/** Sends the given child to the back of the Z-order. 
			In UX markup, use the @SendToBack trigger action instead.
		*/
		public void SendToBack(Visual item)
		{
			AssignNaturalZOrder(); // ensures _naturalZOrder is up to date

			var minNaturalZOrder = int.MaxValue;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (v != item && v.Layer == item.Layer && v._naturalZOrder < minNaturalZOrder) minNaturalZOrder = v._naturalZOrder;
			
			if (minNaturalZOrder != int.MaxValue && minNaturalZOrder-1 != item._naturalZOrder)
			{
				item._naturalZOrder = minNaturalZOrder-1;
				item._zOrderFixed = true;
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

			AssignNaturalZOrder();

			var zOrder = new Visual[_visualChildCount];

			bool needsSorting = false;
			Layer layer = Layer.Underlay;
			bool hasLayer = false;
			int i = 0;
			for (var v = LastChild<Visual>(); v != null; v = v.PreviousSibling<Visual>(), i++)
			{
				zOrder[i] = v;
				if (v.ZOffset != 0) needsSorting = true;
				if (v._zOrderFixed) needsSorting = true;
				if (!hasLayer) { layer = v.Layer; hasLayer = true; }
				else if (v.Layer != layer) needsSorting = true;
			}

			if (needsSorting)
				Array.Sort(zOrder, ZOrderComparator);

			return zOrder;
		}

		void AssignNaturalZOrder()
		{
			int i = 0;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				if (!v._zOrderFixed) v._naturalZOrder = i--;
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

		/** Whether this visual has any visual child nodes. */
		public bool HasVisualChildren { get { return VisualChildCount > 0; } }

		/**  Get the Visual for a given z-order

			This method might have a surprisingly high performance impact; avoid calling it in
			performance sensitive code-paths.
		*/
		public Visual GetZOrderChild(int index)
		{
			return GetCachedZOrder()[index];
		}
	}
}
