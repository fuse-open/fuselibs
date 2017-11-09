using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public partial class State
	{
		static State()
		{
			ScriptClass.Register(typeof(State),
				new ScriptMethod<State>("goto", goto_)
			);
		}
			
		void ignore() {}
		
		/**
			Tells the parent @StateGroup to transition to this state.
			
			@scriptmethod goto()
		*/
		static void goto_(State n)
		{
			n.Goto();
		}
	}
}
