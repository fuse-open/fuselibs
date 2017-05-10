using Uno.UX;

namespace Fuse.Input.UX
{
	public static class AttachedPointerMembers
	{
		[UXAttachedEventAdder("Pointer.Pressed")]
		/** Called when a pointer is pressed on the visual. */
		public static void AddPressedHandler(Visual node, PointerPressedHandler handler)
		{
			Pointer.Pressed.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.Pressed")]
		public static void RemovePressedHandler(Visual node, PointerPressedHandler handler)
		{
			Pointer.Pressed.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Pointer.Moved")]
		/** Called when a pointer is moved on a visual. */
		public static void AddMovedHandler(Visual node, PointerMovedHandler handler)
		{
			Pointer.Moved.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.Moved")]
		public static void RemoveMovedHandler(Visual node, PointerMovedHandler handler)
		{
			Pointer.Moved.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Pointer.Released")]
		/** Called when a pointer is released on a visual. */
		public static void AddReleasedHandler(Visual node, PointerReleasedHandler handler)
		{
			Pointer.Released.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.Released")]
		public static void RemoveReleasedHandler(Visual node, PointerReleasedHandler handler)
		{
			Pointer.Released.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Pointer.Entered")]
		/** Called when a pointer enters a visual. */
		public static void AddEnteredHandler(Visual node, PointerEnteredHandler handler)
		{
			Pointer.Entered.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.Entered")]
		public static void RemoveEnteredHandler(Visual node, PointerEnteredHandler handler)
		{
			Pointer.Entered.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Pointer.Left")]
		/** Called when a pointer leaves a visual. */
		public static void AddLeftHandler(Visual node, PointerLeftHandler handler)
		{
			Pointer.Left.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.Left")]
		public static void RemoveLeftHandler(Visual node, PointerLeftHandler handler)
		{
			Pointer.Left.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Pointer.WheelMoved")]
		/** Called when a pointer wheel is moved on a visual. */
		public static void AddWheelMovedHandler(Visual node, PointerWheelMovedHandler handler)
		{
			Pointer.WheelMoved.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Pointer.WheelMoved")]
		public static void RemoveWheelMovedHandler(Visual node, PointerWheelMovedHandler handler)
		{
			Pointer.WheelMoved.RemoveHandler(node, handler);
		}
	}
}