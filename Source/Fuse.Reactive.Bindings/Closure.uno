using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Fuse.Scripting;

namespace Fuse.Reactive
{
	public class ClosureArgs : EventArgs, IScriptEvent
	{
		readonly NameTable _names;

		internal ClosureArgs(NameTable names)
		{
			_names = names;
		}

		public void Serialize(IEventSerializer s)
		{
			var nt = _names;
			int o = nt != null ? nt.Objects.Count-1 : 0;
			while (nt != null)
			{
				for (int e = nt.Entries.Length; e --> 0;)
				{
					var name = nt.Entries[e];
					var obj = _names.Objects[o--];

					s.AddObject(name, obj);
				}
				nt = nt.ParentTable;
			}
		}
	}

	public delegate void ClosureHandler(object sender, ClosureArgs args);

	/** Captures the named UX objects and dependencies in the scope and sends them to a script
		event when ready.
	*/
	public class Closure: Node
	{
		readonly NameTable _nameTable;

		[UXConstructor]
		public Closure([UXAutoNameTable] NameTable nameTable)
		{
			_nameTable = nameTable;
		}

		ClosureHandler _ready;

		/** Fires on the JavaScript thread when all objects in the scope are ready for use by JS logic.

			This event dispatches on the JavaScript thread when the Closure is rooted.

			It also dispatches the handler on the JavaScript thread immediately if the closure is already
			rooted at the time of subscribing to the event.

			This event is intended for use e.g. with JavaScript frameworks
			like Angular 2, where components do not have direct access to UX objects
			through	injected UX	names. Instead, components can listen to this event
			to get access to all the names in the scope of the closure.

			Example with NGUX syntax:

				<Panel ux:Name="foo" />
				<Closure (Ready)="nodeReady($event)" />

			And then in the TypeScript component:

				nodeReady(e) {
					e.foo // holds a reference to the Panel above
				}
		*/
		public event ClosureHandler Ready
		{
			add
			{
				if (IsRootingCompleted)
					ScheduleReady();

				_ready += value;
			}
			remove
			{
				_ready -= value;
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			ScheduleReady();
		}

		void ScheduleReady()
		{
			if (_ready != null)
				_ready(this, new ClosureArgs(_nameTable));
		}
	}
}
