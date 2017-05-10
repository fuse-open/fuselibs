using Uno;

using Fuse;
using Fuse.Input;

namespace FuseTest
{
	/**
		A handler guard for `using` that captures key events globally or to a specifc control.
	*/
	public class KeyboardHandler : IDisposable
	{
		public KeyboardHandler()
		{
			Keyboard.KeyPressed.AddGlobalHandler(OnKeyPressed);
			Keyboard.KeyReleased.AddGlobalHandler(OnKeyReleased);
		}

		Visual _node;
		public KeyboardHandler(Visual node)
		{
			_node = node;
			Keyboard.KeyPressed.AddHandler(node, OnKeyPressed);
			Keyboard.KeyReleased.AddHandler(node, OnKeyReleased);
		}
		
		void IDisposable.Dispose()
		{
			if (_node != null)
			{
				Keyboard.KeyPressed.RemoveHandler(_node, OnKeyPressed);
				Keyboard.KeyReleased.RemoveHandler(_node, OnKeyReleased);
			}
			else
			{
				Keyboard.KeyPressed.RemoveGlobalHandler(OnKeyPressed);
				Keyboard.KeyReleased.RemoveGlobalHandler(OnKeyReleased);
			}
		}
		
		public KeyPressedArgs LastKeyPressedArgs;
		public KeyReleasedArgs LastKeyReleasedArgs;
		
		void OnKeyPressed(object s, KeyPressedArgs args)
		{
			LastKeyPressedArgs = args;
		}
		
		void OnKeyReleased(object s, KeyReleasedArgs args)
		{
			LastKeyReleasedArgs = args;
		}
	}
}