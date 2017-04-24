
namespace Fuse.Input
{
	public abstract class CustomPointerEventArgs : PointerEventArgs
	{
		protected CustomPointerEventArgs(PointerEventArgs args, Visual visual)
			: base(args.Data, visual)
		{

		}
	}

	// --- PointerPressed ----

	public class PointerPressedArgs: PointerEventArgs
	{
		public PointerPressedArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}

	public delegate void PointerPressedHandler(object sender, PointerPressedArgs args);

	sealed class PointerPressed: VisualEvent<PointerPressedHandler, PointerPressedArgs>
	{
		protected override void Invoke(PointerPressedHandler handler, object sender, PointerPressedArgs args)
		{
			handler(sender, args);
		}
	}


	// --- PointerMoved ----

	public class PointerMovedArgs: PointerEventArgs
	{
		public PointerMovedArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}

	public delegate void PointerMovedHandler(object sender, PointerMovedArgs args);

	sealed class PointerMoved: VisualEvent<PointerMovedHandler, PointerMovedArgs>
	{
		protected override void Invoke(PointerMovedHandler handler, object sender, PointerMovedArgs args)
		{
			handler(sender, args);
		}
	}


	// --- PointerReleased ----

	public class PointerReleasedArgs: PointerEventArgs
	{
		public PointerReleasedArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}

	public delegate void PointerReleasedHandler(object sender, PointerReleasedArgs args);

	sealed class PointerReleased: VisualEvent<PointerReleasedHandler, PointerReleasedArgs>
	{
		protected override void Invoke(PointerReleasedHandler handler, object sender, PointerReleasedArgs args)
		{
			handler(sender, args);
		}
	}


	// --- PointerEntered ----

	public class PointerEnteredArgs: PointerEventArgs
	{
		public PointerEnteredArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}
	public delegate void PointerEnteredHandler(object sender, PointerEnteredArgs args);

	sealed class PointerEntered: VisualEvent<PointerEnteredHandler, PointerEnteredArgs>
	{
		protected override void Invoke(PointerEnteredHandler handler, object sender, PointerEnteredArgs args)
		{
			handler(sender, args);
		}
	}


	// --- PointerLeft ----

	public class PointerLeftArgs: PointerEventArgs
	{
		public PointerLeftArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}

	public delegate void PointerLeftHandler(object sender, PointerLeftArgs args);

	sealed class PointerLeft: VisualEvent<PointerLeftHandler, PointerLeftArgs>
	{
		protected override void Invoke(PointerLeftHandler handler, object sender, PointerLeftArgs args)
		{
			handler(sender, args);
		}
	}


	// --- PointerWheel ----

	public class PointerWheelMovedArgs: PointerEventArgs
	{
		public PointerWheelMovedArgs(PointerEventData data, Visual visual)
			: base(data, visual)
		{ }
	}

	public delegate void PointerWheelMovedHandler(object sender, PointerWheelMovedArgs args);

	sealed class PointerWheelMoved: VisualEvent<PointerWheelMovedHandler, PointerWheelMovedArgs>
	{
		protected override void Invoke(PointerWheelMovedHandler handler, object sender, PointerWheelMovedArgs args)
		{
			handler(sender, args);
		}
	}
	
}