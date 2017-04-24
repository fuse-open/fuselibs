using Uno;

namespace Fuse.Controls
{
	[Flags]
	/**
		Specifies which scroll directions are allowed, or considered, in a control or gesture.
	*/
	public enum ScrollDirections
	{
		Left = 1<<0,
		Right = 1<<1,
		Up = 1<<2,
		Down = 1<<3,
		Horizontal = Left | Right,
		Vertical = Up | Down,
		Both = Horizontal | Vertical,
		All = Both,
	}
}
