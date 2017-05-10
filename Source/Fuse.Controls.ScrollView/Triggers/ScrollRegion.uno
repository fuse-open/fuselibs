using Uno;
using Uno.UX;

using Fuse.Controls;

namespace Fuse.Triggers
{
	public interface IScrolledLength
	{
		float2 GetPoints(float value, ScrollViewBase scrollable);
	}
	
	public static class IScrolledLengths
	{
		class PointsLength : IScrolledLength
		{
			public float2 GetPoints(float value, ScrollViewBase scrollable)
			{
				return float2(value);
			}
		}
		[UXGlobalResource("Points")] 
		/** Values are expressed in points in the ScrollView */
		public static readonly IScrolledLength Points = new PointsLength();
		
		
		class PixelsLength : IScrolledLength
		{
			public float2 GetPoints(float value, ScrollViewBase scrollable)
			{
				return float2(value) / scrollable.AbsoluteZoom;
			}
		}
		[UXGlobalResource("Pixels")] 
		/** Values are expressed in points in the ScrollView */
		public static readonly IScrolledLength Pixels = new PixelsLength();
		
		
		class ContentSizeLength : IScrolledLength
		{
			public float2 GetPoints(float value, ScrollViewBase scrollable)
			{
				return value * (scrollable.MaxScroll - scrollable.MinScroll);
			}
		}
		
		[UXGlobalResource("ContentSize")] 
		/** Value is a fraction of the Content size of the ScrollView */
		public static readonly IScrolledLength ContentSize = new ContentSizeLength();
		
		
		class ScrollViewSizeLength : IScrolledLength
		{
			public float2 GetPoints(float value, ScrollViewBase scrollable)
			{
				return value * scrollable.ActualSize;
			}
		}
		
		[UXGlobalResource("ScrollViewSize")] 
		/** Value is a fraction of the Content size of the ScrollView */
		public static readonly IScrolledLength ScrollViewSize = new ScrollViewSizeLength();
	}
	
	/** A relative location in a ScrollView */
	public enum ScrolledWhere
	{
		/** Indicates the property is not being used. */
		None,
		/** The start of the scrolling area, at @ScrollView.MinScroll */
		Start,
		/** The end of the scrolling area, at @ScrollView.MaxScroll */
		End,
	}
	
	class ScrollRegion
	{
		public ScrolledWhere To = ScrolledWhere.None;
		public bool SetTo( ScrolledWhere value )
		{
			if (To == value)
				return false;
			To = value;
			return true;
		}
		
		public float Within;
		public bool SetWithin( float value )
		{
			if (Within == value)
				return false;
			Within = value;
			return true;
		}
		
		public IScrolledLength RelativeTo = IScrolledLengths.Points;
		public bool SetRelativeTo( IScrolledLength value )
		{
			if (RelativeTo == value)
				return false;
			RelativeTo = value;
			return true;
		}
		
		float2 CalcWithin(ScrollViewBase scrollable)
		{
			return RelativeTo.GetPoints(Within, scrollable);
		}
		
		public bool IsInZone(ScrollViewBase scrollable)
		{
			var w = CalcWithin(scrollable);
			
			var sw = scrollable.ToScalarPosition(w);
			var sp = scrollable.ToScalarPosition(scrollable.ScrollPosition);

			switch (To)
			{
				case ScrolledWhere.None:
					return false;
					
				case ScrolledWhere.Start:
				{
					var smin = scrollable.ToScalarPosition(scrollable.MinScroll);
					return sp <= smin + sw;
				}
					
				case ScrolledWhere.End:
				{
					var smax = scrollable.ToScalarPosition(scrollable.MaxScroll);
					return sp >= smax - sw;
				}
			}
			
			return false;
		}
	}
}