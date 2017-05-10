
namespace Fuse.Drawing
{
	public enum LineCap
	{
		Butt,
		Round,
		Square
	}

	public enum LineJoin
	{
		Miter,
		Round,
		Bevel,
	}

	public enum FillRule
	{
		NonZero, EvenOdd
	}

	public enum Antialiasing
	{
		None, Gradient
	}

	public enum ResampleMode
	{
		Nearest,
		Linear,
		Mipmap
	}

	public enum WrapMode
	{
		Repeat,
		ClampToEdge
	}
}
