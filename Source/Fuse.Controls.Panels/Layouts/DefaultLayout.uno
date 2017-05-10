using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Layouts
{

	public sealed class DefaultLayout : Layout
	{
		internal override float2 GetContentSize(IList<Node> elements, LayoutParams lp)
		{
			var size = GetElementsSize(elements, lp);
			
			/*
			bool recalc = false;
			if (!fillSet.HasFlag(Size_Flags.X))
			{
				fillSize.X = size.X;
				fillSet |= Size_Flags.X;
				recalc = true;
			}
			if (!fillSet.HasFlag(Size_Flags.Y))
			{
				fillSize.Y = size.Y;
				fillSet |= Size_Flags.Y;
				recalc = true;
			}
			
			if (recalc)
				size = GetElementsSize(elements, fillSize, fillSet);
			*/
				
			return size;
		}

		float2 GetElementsSize(IList<Node> elements, LayoutParams lp)
		{
			var ds = float2(0);
			for (int i = 0; i < elements.Count; i++)
			{
				var e = elements[i] as Visual;
				if (!AffectsLayout(e)) continue;

				ds = Math.Max( ds, e.GetMarginSize(lp) );
			}
			return ds;
		}

		internal override void ArrangePaddingBox(IList<Node> elements, float4 padding, LayoutParams lp)
		{
			var av = lp.CloneAndDerive();
			av.RemoveSize(padding.XY+padding.ZW);
			for (int i = 0; i < elements.Count; i++)
			{
				var e = elements[i] as Visual;
				if (e == null) continue;
				if (!ArrangeMarginBoxSpecial(e, padding, lp))
				{
					e.ArrangeMarginBox(padding.XY, av);
				}
			}
		}
		
		internal override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			//only if the element itself is dependent
			return LayoutDependent.Maybe;
		}
	}

}