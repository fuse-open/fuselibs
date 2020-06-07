using Uno;

namespace Fuse.Elements
{
	public enum Visibility
	{
		/** The element is visible and part of the layout */
		Visible,
		/** The element is invisible and takes up no space in layout */
		Collapsed,
		/** The element is invisible but nonetheless occupies space in the layout (the layout of it and its children are calculated normally). Hidden elemenets nonetheless do not participate in hit testing. */
		Hidden
	}

	/**
		Refers to the alignment of an element, or content, in its parent.

		This encodes both a vertical and horizontal alignment.

		- `Left`, `HorizontalCenter`, `Right` specify horizontal alignment
		- `Top`, `VerticalCenter`, `Bottom` specify vertical alignment

		@see Layout
	*/
	public enum Alignment
	{
		/** Default alignment */
		Default = 0,

		/** Aligns element to the left. */
		Left = 1,

		/** Centers element horizontally. */
		HorizontalCenter = 2,

		/** Aligns element to the right. */
	    Right = 3,

		/** Aligns element to the top. */
	    Top = 1<<2,

		/** Centers element vertically. */
	    VerticalCenter = 2<<2,

		/** Aligns element to the bottom. */
	    Bottom = 3<<2,

		/** Aligns element to the top left corner. */
	    TopLeft = Left | Top,

		/** Centers element horizontally and aligns it to the top. */
	    TopCenter = HorizontalCenter | Top,

		/** Aligns element to the top right corner. */
	    TopRight = Right | Top,

		/** Centers element vertically and aligns it to the left. */
	    CenterLeft = Left | VerticalCenter,

		/** Centers element both horizontally and vertically. */
	    Center = HorizontalCenter | VerticalCenter,

		/** Centers element vertically and aligns it to the right. */
	    CenterRight = Right | VerticalCenter,

		/** Aligns element to the bottom left corner. */
	    BottomLeft = Left | Bottom,

		/** Centers element horizontally and aligns it to the bottom. */
	    BottomCenter = HorizontalCenter | Bottom,

		/** Aligns element to the bottom right corner. */
	    BottomRight = Right | Bottom
	}

	public static class AlignmentHelpers
	{
		public static Alignment GetVerticalAlign(Alignment a)
		{
			return (Alignment)((int)a & (3<<2));
		}
		public static Alignment GetHorizontalAlign(Alignment a)
		{
			return (Alignment)((int)a & 3);
		}

		public static float2 GetAnchor(Alignment a)
		{
			var h = GetHorizontalAlign(a);
			var x = h == Alignment.Left ? 0f :
				h == Alignment.Right ? 1f : 0.5f;

			var v = GetVerticalAlign(a);
			var y = v == Alignment.Top ? 0f :
				v == Alignment.Bottom ? 1f : 0.5f;

			return float2(x,y);
		}

		internal static SimpleAlignment GetVerticalSimpleAlign(Alignment a)
		{
			var raw = AlignmentHelpers.GetVerticalAlign(a);
			if (raw == Alignment.Bottom)
				return SimpleAlignment.End;
			if (raw == Alignment.VerticalCenter)
				return SimpleAlignment.Center;
			return SimpleAlignment.Begin;
		}

		internal static SimpleAlignment GetHorizontalSimpleAlign(Alignment a)
		{
			var raw = AlignmentHelpers.GetHorizontalAlign(a);
			if (raw == Alignment.Right)
				return SimpleAlignment.End;
			if (raw == Alignment.HorizontalCenter)
				return SimpleAlignment.Center;
			return SimpleAlignment.Begin;
		}

		internal static OptionalSimpleAlignment GetVerticalSimpleAlignOptional(Alignment a)
		{
			var raw = AlignmentHelpers.GetVerticalAlign(a);
			if (raw == Alignment.Top)
				return OptionalSimpleAlignment.Begin;
			if (raw == Alignment.VerticalCenter)
				return OptionalSimpleAlignment.Center;
			if (raw == Alignment.Bottom)
				return OptionalSimpleAlignment.End;
			return OptionalSimpleAlignment.None;
		}

		internal static OptionalSimpleAlignment GetHorizontalSimpleAlignOptional(Alignment a)
		{
			var raw = AlignmentHelpers.GetHorizontalAlign(a);
			if (raw == Alignment.Left)
				return OptionalSimpleAlignment.Begin;
			if (raw == Alignment.HorizontalCenter)
				return OptionalSimpleAlignment.Center;
			if (raw == Alignment.Right)
				return OptionalSimpleAlignment.End;
			return OptionalSimpleAlignment.None;
		}
	}

	enum SimpleAlignment
	{
		Begin,
		Center,
		End
	}

	enum OptionalSimpleAlignment
	{
		None,
		Begin,
		Center,
		End
	}

	public enum CachingMode
	{
		Optimized,
		Always,
		Never
	}

	/**
		Specifies how an image size is calculated and how it is stretched.
	*/
	public enum StretchMode
	{
		/** The size of the source image, in points calculated with density, are used as the image size. This is the default: a 100x50 source image will be 100x50 points in size. This preserves size across various device densities. */
		PointPrecise,
		/** The size is pixel matched to the source so the image is drawn 1:1. This means the visual size changes across device densities, but the image remains sharp. */
		PixelPrecise,
		/** If the size of the image in `PixelPrecise` mode is close to `PointPrecise` then use `PixelPrecise` mode, otherwise use `PointPrecise` mode. This retains sharpness with slightly varying sizes, but prevents too much size variation. */
		PointPrefer,
		/** The image is stretched to fill the available space. The aspect ratio is not retained. */
		Fill,
		/** The image is stretched in 9-segments defined by the `Scale9Margin`. Corners are not stretched, borders are stretced in one direction, the center is stretched in both directions. */
		Scale9,
		/** Stretches the image to touch the sides of the available space and retain the aspect ratio. This will result in unfilled sections on either the left/right or top/bottom sides of the image. */
		Uniform,
		/** Stretches an image to touch all sides of the available space and retain the aspect ratio. This will result in the image being clipped on the left/right or top/bottom. */
		UniformToFill
	}

	/**
		Specifies whether an image can become larger or smaller to fill the available space.
	*/
	public enum StretchDirection
	{
		/** An image can be stretched both larger and smaller. */
		Both,
		/** An image will only be expanded to fill up available space, it will not shrink. */
		UpOnly,
		/** An image will only be shrunk to fit in the available space, it will not expand. */
		DownOnly
	}

	/**
		Specifies how the size of an image is calculated during layout.
	*/
	public enum StretchSizing
	{
		/** The size of the image of the image will be reported as 0 for unknown dimensions during initial calculations. */
		Zero,
		/** The natural size of the image, based on Source/Density will be used */
		Natural,
	}
}