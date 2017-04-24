
namespace Fuse.Input
{
	
	// --- FocusGained ---

	public class FocusGainedArgs: VisualEventArgs
	{
		public FocusGainedArgs(Visual visual): base(visual)
		{ }
	}
	public delegate void FocusGainedHandler(object sender, FocusGainedArgs args);

	sealed class FocusGained: VisualEvent<FocusGainedHandler, FocusGainedArgs>
	{
		protected override void Invoke(FocusGainedHandler handler, object sender, FocusGainedArgs args)
		{
			handler(sender, args);
		}
	}


	// --- FocusLost ---

	public class FocusLostArgs: VisualEventArgs
	{
		public FocusLostArgs(Visual visual): base(visual)
		{ }
	}
	public delegate void FocusLostHandler(object sender, FocusLostArgs args);

	sealed class FocusLost: VisualEvent<FocusLostHandler, FocusLostArgs>
	{
		protected override void Invoke(FocusLostHandler handler, object sender, FocusLostArgs args)
		{
			handler(sender, args);
		}
	}


	public class IsFocusableChangedArgs: VisualEventArgs
	{
		public IsFocusableChangedArgs(Visual visual): base(visual) {}
	}

	public delegate void IsFocusableChangedHandler(object sender, IsFocusableChangedArgs args);

	class IsFocusableChangedEvent : VisualEvent<IsFocusableChangedHandler, IsFocusableChangedArgs>
	{
		protected override void Invoke(IsFocusableChangedHandler handler, object sender, IsFocusableChangedArgs args)
		{
			handler(sender, args);
		}
	}


	
}