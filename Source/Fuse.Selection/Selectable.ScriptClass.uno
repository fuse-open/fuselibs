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
				new ScriptMethod<Selectable>("add", add),
				new ScriptMethod<Selectable>("remove", remove),
				new ScriptMethod<Selectable>("toggle", toggle));
		}

		/**
			Adds this selectable to its Selection.
			
			This follows the high level selection rules (such as MaxCount and Replace).
		*/
		static void add(Selectable s)
		{
			s.Add();
		}
		
		/**
			Removes this selectable from its Selection.
			
			This follows the high level selection rules (such as MinCount).
			
			If the Selectable is not currently selected then nothing is removed.
		*/
		static void remove(Selectable s)
		{
			s.Remove();
		}
		
		/**
			Toggles the selection of the Selectable in its selection. If already selected then removes it, otherwise adds it.
			
			This follows the high level selection rules (such as MaxCount/MinCount).
		*/
		static void toggle(Selectable s)
		{
			s.Toggle();
		}
		
	}
}
