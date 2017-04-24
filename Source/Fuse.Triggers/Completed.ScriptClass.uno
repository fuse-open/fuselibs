using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public partial class Completed
	{
		static Completed()
		{
			ScriptClass.Register(typeof(Completed),
				new ScriptMethod<Completed>("reset", reset, ExecutionThread.MainThread)
			);
		}
		
		/**
			Resets the `Completed` trigger allowing it to trigger again.
			
			This can be useful when you modify many variables that are bound to the UX. You can reset an existing `Completed` trigger, allowing it to pulse again once the results of all those new variables have been reflected in the UI.
			
			@scriptmethod reset()
		*/
		static void reset(Context c, Completed cp, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "Completed.reset takes no arguments", cp );
				return;
			}
			
			cp.Reset();
		}
	}
}
