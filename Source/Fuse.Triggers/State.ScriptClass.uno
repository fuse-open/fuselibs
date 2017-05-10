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
				new ScriptMethod<State>("goto", goto_, ExecutionThread.MainThread)
			);
		}
			
		void ignore() {}
		
		/**
			Transtions the parent @StateGroup to this state.
			
			@scriptmethod goto()
		*/
		static void goto_(Context c, State n, object[] args)
		{
			n.Goto();
		}
	}
}