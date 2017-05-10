using Uno;

namespace Fuse.Triggers
{
	/**
		A common base for pulse-like triggers (thus that pulse when an event is triggered).
		
		NOTE: Not all the pulse-like triggers have been migrated to this base class yet.
	*/
	public abstract class PulseTrigger<ArgsT> : Trigger
		where ArgsT : EventArgs 
	{
		public delegate void PulseHandler(object sender, ArgsT args);

		/**
			An event that is called whenever the action pulses.
		*/
		public event PulseHandler Handler;
		
		protected void Pulse(ArgsT args)
		{
			Pulse();
			if (Handler != null)
				Handler(this, args);
		}
		
		static internal void AddHandlerImpl<T>(Visual visual, PulseHandler handler)
			where T : PulseTrigger<ArgsT>, new()
		{
			T r = visual.FirstChild<T>();
			if (r == null)
			{
				r = new T();
				visual.Children.Add(r);
			}

			r.Handler += handler;
		}
		
		static internal void RemoveHandlerImpl<T>(Visual visual, PulseHandler handler)
			where T : PulseTrigger<ArgsT>
		{
			T r = visual.FirstChild<T>();

			if (r != null)
				r.Handler -= handler;
		}
	}
}
