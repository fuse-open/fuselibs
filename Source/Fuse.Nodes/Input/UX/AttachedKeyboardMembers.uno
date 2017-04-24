using Uno.UX;

namespace Fuse.Input.UX
{
	public static class AttachedKeyboardMembers
	{
		[UXAttachedEventAdder("Keyboard.KeyPressed")]
		/** Called when a @Visual receives a key press event while having input focus. 
			On mobile devices, keyboard input only applies to physical buttons (such as BackButton), not soft keyboards.
		*/
		public static void AddKeyPressedHandler(Visual node, KeyPressedHandler handler)
		{
			Keyboard.KeyPressed.AddHandler(node, handler);
		}

		[UXAttachedEventRemover("Keyboard.KeyPressed")]
		public static void RemoveKeyPressedHandler(Visual node, KeyPressedHandler handler)
		{
			Keyboard.KeyPressed.RemoveHandler(node, handler);
		}

		[UXAttachedEventAdder("Keyboard.KeyReleased")]
		/** Called when a @Visual receives a key release event while having input focus. 
			On mobile devices, keyboard input only applies to physical buttons (such as BackButton), not soft keyboards.
		*/
		public static void AddKeyReleasedHandler(Visual node, KeyReleasedHandler handler)
		{
			Keyboard.KeyReleased.AddHandler(node, handler);	
		}

		[UXAttachedEventRemover("Keyboard.KeyReleased")]
		public static void RemoveKeyReleasedHandler(Visual node, KeyReleasedHandler handler)
		{
			Keyboard.KeyReleased.RemoveHandler(node, handler);
		}
	}
}