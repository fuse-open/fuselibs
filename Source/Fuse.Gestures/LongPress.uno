using Uno;
using Fuse.Input;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	public class LongPressedArgs : CustomPointerEventArgs
	{
		public LongPressedArgs(PointerEventArgs args, Visual visual)
			: base(args, visual)
		{
		}
	}

	public delegate void LongPressedHandler(object sender, LongPressedArgs args);

	/** Triggers when a pointer is held down for a period of time.

		Being @LongPressed does not prevent other gestures, like @Clicked, from also triggering on the visual.
	*/
	public class LongPressed : ClickerTrigger
	{
		/**
		An *optional* JavaScript function to be called when the pointer is held down for a period of time.
		*/
		public event LongPressedHandler Handler;

		protected override void OnRooted()
		{
			base.OnRooted();
			Clicker.LongPressedEvent += OnLongPressed;
		}

		protected override void OnUnrooted()
		{
			Clicker.LongPressedEvent -= OnLongPressed;
			base.OnUnrooted();
		}

		void OnLongPressed(PointerEventArgs args, int count)
		{
			if (!Accept(args))
				return;
			
			Pulse();
			if (Handler != null)
				Handler(this, new LongPressedArgs(args, Parent));
		}
	}
}
