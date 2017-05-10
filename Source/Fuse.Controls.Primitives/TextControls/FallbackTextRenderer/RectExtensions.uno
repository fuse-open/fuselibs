using Uno;

namespace Fuse.Controls.FallbackTextRenderer
{
	static class RectExtensions
	{
		public static Rect MoveRectToContainRect(this Rect a, Rect b)
		{
			var pos = a.Position;
			var newX = pos.X;
			var newY = pos.Y;

			if (a.Size.X < b.Size.X || b.Left < a.Left)
			{
				newX = b.Left;
			}
			else if (b.Right > a.Right)
			{
				newX += b.Right - a.Right;
			}

			if (a.Size.Y < b.Size.Y || b.Top < a.Top)
			{
				newY = b.Top;
			}
			else if (b.Bottom > a.Bottom)
			{
				newY += b.Bottom - a.Bottom;
			}

			return new Rect(float2(newX, newY), a.Size);
		}

		public static Rect MoveRectInsideRect(this Rect a, Rect b)
		{
			var pos = a.Position;
			var newX = pos.X;
			var newY = pos.Y;

			if (b.Left > a.Left)
			{
				newX = b.Left;
			}
			else if (b.Right < a.Right)
			{
				newX -= a.Right - b.Right;
			}

			if (b.Top > a.Top)
			{
				newY = b.Left;
			}
			else if (b.Bottom < a.Bottom)
			{
				newY -= a.Bottom - b.Bottom;
			}

			return new Rect(float2(newX, newY), a.Size);
		}
	}
}
