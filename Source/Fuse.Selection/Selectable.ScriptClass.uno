using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Selection
{

	public partial class Selectable
	{
		static Selectable()
		{
			ScriptClass.Register(typeof(Selectable),
				new ScriptMethod<Selectable>("add", add, ExecutionThread.MainThread),
				new ScriptMethod<Selectable>("remove", remove, ExecutionThread.MainThread),
				new ScriptMethod<Selectable>("toggle", toggle, ExecutionThread.MainThread));
		}

		/**
			Adds this selectable to its Selection.
			
			This follows the high level selection rules (such as MaxCount and Replace).
		*/
		static void add(Context c, Selectable s, object[] args )
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "add requires 0 arguments", s );
				return;
			}
			
			s.Add();
		}
		
		/**
			Removes this selectable from its Selection.
			
			This follows the high level selection rules (such as MinCount).
			
			If the Selectable is not currently selected then nothing is removed.
		*/
		static void remove(Context c, Selectable s, object[] args )
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "remove requires 0 arguments", s );
				return;
			}
			
			s.Remove();
		}
		
		/**
			Toggles the selection of the Selectable in its selection. If already selected then removes it, otherwise adds it.
			
			This follows the high level selection rules (such as MaxCount/MinCount).
		*/
		static void toggle(Context c, Selectable s, object[] args )
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "toggle requires 0 arguments", s );
				return;
			}
			
			s.Toggle();
		}
		
	}
}