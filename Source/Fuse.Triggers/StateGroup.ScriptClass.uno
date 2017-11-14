using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Triggers
{
	public partial class StateGroup
	{
		static StateGroup()
		{
			ScriptClass.Register(typeof(StateGroup), 
				new ScriptMethod<StateGroup>("goto", goto_),
				new ScriptMethod<StateGroup>("gotoNext", gotoNext)
			);
		}

		static bool StateAcceptor(object o)
		{
			return o is State;
		}

		static void gotoName(StateGroup n, string name)
		{
			var state = n.FindObjectByName(name, StateAcceptor) as State;
			if (state == null)
			{
				Fuse.Diagnostics.UserError( "Unable to find State with Name: " + name, n);
				return;
			}
			n.Goto(state);
		}
		
		/**
			Transition to a target state.
			
			@scriptmethod goto( name )
			@param name The name of the target state.
			
			@scriptmethod goto( state )
			@param state The state object for the target state. This must be a @State that already 
				exists in this @StateGroup.
		*/
		static void goto_(StateGroup n, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "StateGroup.goto requires 1 argument", n );
				return;
			}
			
			if (args[0] is string)
				gotoName(n, args[0] as string);
			else
				n.Goto(args[0] as State);
		}
		
		/**
			Transition to the next state (the one after the current one). This wraps around to the first state
			if at the last one.
			
			@scriptmethod gotoNext()
		*/
		static void gotoNext(StateGroup n)
		{
			n.GotoNextState();
		}
	}
}
