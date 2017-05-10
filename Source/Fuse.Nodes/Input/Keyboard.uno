using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Input
{

	public abstract class KeyEventArgs: VisualEventArgs
	{
		public Uno.Platform.Key Key
		{
			get;
			private set;
		}

		public bool IsMetaKeyPressed
        {
            get;
            protected set;
        }
        
        public bool IsControlKeyPressed
        { 
            get;
            protected set;
        }
        
        public bool IsShiftKeyPressed 
        { 
            get;
            protected set;
        }
        
        public bool IsAltKeyPressed 
        {
            get;
            protected set;
        }

		protected KeyEventArgs(Uno.Platform.Key key, Visual visual): base(visual)
		{
			Key = key;
		}
	}

	public class KeyPressedArgs: KeyEventArgs
	{
		public KeyPressedArgs(Uno.Platform.Key key, bool isMetaKeyPressed, bool isControlKeyPressed, bool isShiftKeyPressed, bool isAltKeyPressed, Visual visual): base(key, visual)
		{
			IsMetaKeyPressed = isMetaKeyPressed;
			IsControlKeyPressed = isControlKeyPressed;
			IsShiftKeyPressed = isShiftKeyPressed;
			IsAltKeyPressed = isAltKeyPressed;
		}
	}

	public delegate void KeyPressedHandler(object sender, KeyPressedArgs args);

	sealed class KeyPressed: VisualEvent<KeyPressedHandler, KeyPressedArgs>
	{
		protected override void Invoke(KeyPressedHandler handler, object sender, KeyPressedArgs args)
		{
			handler(sender, args);
		}
	}

	public class KeyReleasedArgs: KeyEventArgs
	{
		public KeyReleasedArgs(Uno.Platform.Key key, bool isMetaKeyPressed, bool isControlKeyPressed, bool isShiftKeyPressed, bool isAltKeyPressed, Visual visual): base(key, visual)
		{
			IsMetaKeyPressed = isMetaKeyPressed;
			IsControlKeyPressed = isControlKeyPressed;
			IsShiftKeyPressed = isShiftKeyPressed;
			IsAltKeyPressed = isAltKeyPressed;
		}
	}

	public delegate void KeyReleasedHandler(object sender, KeyReleasedArgs args);

	sealed class KeyReleased: VisualEvent<KeyReleasedHandler, KeyReleasedArgs>
	{
		protected override void Invoke(KeyReleasedHandler handler, object sender, KeyReleasedArgs args)
		{
			handler(sender, args);
		}
	}

	public static class Keyboard
	{
		static readonly KeyPressed _keyPressed = new KeyPressed();
		static readonly KeyReleased _keyReleased = new KeyReleased();

		public static VisualEvent<KeyPressedHandler, KeyPressedArgs> KeyPressed { get { return _keyPressed; } }
		public static VisualEvent<KeyReleasedHandler, KeyReleasedArgs> KeyReleased { get { return _keyReleased; } }

		public static void AddHandlers(Visual visual, KeyPressedHandler pressed = null, KeyReleasedHandler released = null)
		{
			if (pressed != null) KeyPressed.AddHandler(visual, pressed);
			if (released != null) KeyReleased.AddHandler(visual, released);
		}

		public static void RemoveHandlers(Visual visual, KeyPressedHandler pressed = null, KeyReleasedHandler released = null)
		{
			if (pressed != null) KeyPressed.RemoveHandler(visual, pressed);
			if (released != null) KeyReleased.RemoveHandler(visual, released);
		}

		static List<Uno.Platform.Key> _keysDown = new List<Uno.Platform.Key>();
		static readonly PropertyHandle _keyboardHandle = Fuse.Properties.CreateHandle();

		public static void EmulateBackButtonTap()
		{
			UpdateManager.PostAction(DispatchEmulateBackButtonTap);
		}

		static void DispatchEmulateBackButtonTap()
		{
			RaiseKeyPressed(Uno.Platform.Key.BackButton, false, false, false, false);
			RaiseKeyReleased(Uno.Platform.Key.BackButton, false, false, false, false);
		}

		static Visual KeyTargetVisual
		{	
			get
			{
				return Focus.FocusedVisual ?? AppBase.CurrentRootViewport;
			}
		}
		
		public static bool RaiseKeyPressed(Uno.Platform.Key key, bool isMetaKeyPressed, bool isControlKeyPressed, bool isShiftKeyPressed, bool isAltKeyPressed)
		{
			_keysDown.Add(key);

			var args = new KeyPressedArgs(key, isMetaKeyPressed, isControlKeyPressed, isShiftKeyPressed, isAltKeyPressed, KeyTargetVisual);	
			KeyPressed.RaiseWithBubble(args);

			return args.IsHandled;
		}

		public static bool RaiseKeyReleased(Uno.Platform.Key key, bool isMetaKeyPressed, bool isControlKeyPressed, bool isShiftKeyPressed, bool isAltKeyPressed)
		{
			for (int i = 0; i < _keysDown.Count; i++)
				if (_keysDown[i] == key)
					_keysDown.RemoveAt(i--);

			var args = new KeyReleasedArgs(key, isMetaKeyPressed, isControlKeyPressed, isShiftKeyPressed, isAltKeyPressed, KeyTargetVisual);
			KeyReleased.RaiseWithBubble(args);

			return args.IsHandled;
		}

		public static bool IsKeyPressed(Uno.Platform.Key key)
		{
			for (int i = 0; i < _keysDown.Count; i++)
			{
				if (_keysDown[i] == key) return true;
			}

			return false;
		}
	}

}