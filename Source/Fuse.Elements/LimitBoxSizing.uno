using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	internal sealed class LimitBoxSizing : BoxSizing
	{
		static public LimitBoxSizing Singleton = new LimitBoxSizing();

		override public BoxPlacement CalcBoxPlacement(Element element, float2 position, LayoutParams lp)
		{
			return StandardBoxSizing.Singleton.CalcBoxPlacement(element, position, lp);
		}

		override public float2 CalcMarginSize(Element element, LayoutParams lp)
		{
			var nlp = lp.CloneAndDerive();
			nlp.RetainXY( !element.HasBit(FastProperty1.LimitWidth),	!element.HasBit(FastProperty1.LimitHeight) );

			var std = StandardBoxSizing.Singleton.CalcMarginSize(element, nlp);
			var c = Limit(element, std);
			return c;
		}

		override public float2 CalcArrangePaddingSize(Element element, LayoutParams lp)
		{
			return StandardBoxSizing.Singleton.CalcArrangePaddingSize(element, lp);
		}

		float2 Limit(Element element, float2 std)
		{
			if (element.HasBit(FastProperty1.LimitHeight))
			{
				var height = element.LimitHeight;

				bool known;
				var size = UnitSize(element, height, std.Y, true, out known );
				std.Y = Math.Min(std.Y,size);
			}

			if (element.HasBit(FastProperty1.LimitWidth))
			{
				var width = element.LimitWidth;

				bool known;
				var size = UnitSize(element, width, std.X, true, out known );
				std.X = Math.Min(std.X,size);
			}

			if (element.SnapToPixels)
				std = element.InternSnap(std);

			return std;
		}
	}

	public partial class Element
	{
		/**
			The height limit for an element using `BoxSizing="Limit"`.

			@remarks Docs/BoxSizing.md
		*/
		public Size LimitHeight
		{
			get { return Get(FastProperty1.LimitHeight, Uno.UX.Size.Auto); }
			set
			{
				if (LimitHeight != value)
				{
					Set(FastProperty1.LimitHeight, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

		/**
			The width limit for an element using `BoxSizing="Limit"`.

			@remarks Docs/BoxSizing.md
		*/
		public Size LimitWidth
		{
			get { return Get(FastProperty1.LimitWidth, Uno.UX.Size.Auto); }
			set
			{
				if (LimitWidth != value )
				{
					Set(FastProperty1.LimitWidth, value, Uno.UX.Size.Auto);
					InvalidateLayout();
				}
			}
		}

	}

}
