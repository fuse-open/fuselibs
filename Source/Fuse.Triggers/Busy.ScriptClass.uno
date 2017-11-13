using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public partial class Busy
	{
		static Busy()
		{
			ScriptClass.Register(typeof(Busy), 
				new ScriptMethod<Busy>("activate", activate),
				new ScriptMethod<Busy>("deactivate", deactivate)
			);
		}
		
		/**
			Activates the busy task, setting the parent node as busy. If the busy task is already active then it remains active.
			
			Call this function to explicitly begin the busy activity. 
			
			@scriptmethod activate()
		*/
		static void activate(Busy b)
		{
			b.IsActive = true;
		}
		
		/**
			Deactivates the busy task.
			
			Call this function to end the current busy activity.
			
			@scriptmethod deactivate()
		*/
		static void deactivate(Busy b)
		{
			b.IsActive = false;
		}
	}
}
