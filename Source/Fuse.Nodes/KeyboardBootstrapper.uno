using Uno;
using Uno.UX;
using Uno.Runtime.Implementation;
using Uno.Runtime.Implementation.Internal;

using Fuse.Input;

namespace Fuse
{
	class KeyboardBootstrapper
	{
		public static void OnKeyPressed(object sender, Uno.Platform.KeyEventArgs args)
		{
			try
			{
				if (!args.Handled && args.Key == Uno.Platform.Key.Tab)
				{
					Focus.Move(args.IsShiftKeyPressed ? FocusNavigationDirection.Up : FocusNavigationDirection.Down);
				}

				Keyboard.RaiseKeyPressed(args.Key, args.IsMetaKeyPressed, args.IsControlKeyPressed, args.IsShiftKeyPressed, args.IsAltKeyPressed);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		public static void OnKeyReleased(object sender, Uno.Platform.KeyEventArgs args)
		{
			try
			{
				Keyboard.RaiseKeyReleased(args.Key, args.IsMetaKeyPressed, args.IsControlKeyPressed, args.IsShiftKeyPressed, args.IsAltKeyPressed);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}

		public static void OnTextInput(object sender, Uno.Platform.TextInputEventArgs args)
		{
			try
			{
				args.Handled = TextService.RaiseTextEntered(args.Text);
			}
			catch (Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}
	}
}
