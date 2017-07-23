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
		internal override float2 GetContentSize(Visual container, LayoutParams lp)
		{
			var size = GetElementsSize(container, lp);
			
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
				size = GetElementsSize(container, fillSize, fillSet);
			*/
				
			return size;
		}

		float2 GetElementsSize(Visual container, LayoutParams lp)
		{
			var ds = float2(0);
			for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
			{
				if (!AffectsLayout(e)) continue;

				ds = Math.Max( ds, e.GetMarginSize(lp) );
			}
			return ds;
		}

		internal override void ArrangePaddingBox(Visual container, float4 padding, LayoutParams lp)
		{
			var av = lp.CloneAndDerive();
			av.RemoveSize(padding.XY+padding.ZW);
			for (var e = container.FirstChild<Visual>(); e != null; e = e.NextSibling<Visual>())
			{
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