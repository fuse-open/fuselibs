using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Reactive
{
	partial class ThreadWorker
	{
		List<Observable.Operation> _messages = new List<Observable.Operation>();
		readonly object _messagesMutex = new object();

		List<Observable.Operation> TakeMessages()
		{
			lock (_messagesMutex)
			{
				if (_messages.Count == 0) return null;

				var msgs = _messages;
				_messages = new List<Observable.Operation>();
				return msgs;
			}
		}

		internal void Enqueue(Observable.Operation op)
		{
			lock (_messagesMutex)
				_messages.Add(op);
		}

		// Called from UI thread
		public void ProcessUIMessages()
		{
			var msgs = TakeMessages();
			if (msgs == null) return;

			for (int i = 0; i < msgs.Count; i++)
			{
				msgs[i].Perform();
			}
		}

		// Used for stack overflow protection
		int _reflectionDepth;

		public object Reflect(object obj)
		{
			var e = obj as Scripting.External;
			if (e != null) return e.Object;

			var sobj = obj as Scripting.Object;
			if (sobj != null)
			{
				if (sobj.ContainsKey("external_object"))
				{
					var ext = sobj["external_object"] as Scripting.External;
					if (ext != null) return ext.Object;
				}
			}

			_reflectionDepth++;
			var res = CreateMirror(obj);
			_reflectionDepth--;

			if (res != null) return res;

			return obj;
		}

		object CreateMirror(object obj)
		{
			if (_reflectionDepth > 50)
			{
				Diagnostics.UserWarning("JavaScript data model contains circular references or is too deep. Some data may not display correctly.", this);
				return null;
			}
			
			var a = obj as Scripting.Array;
			if (a != null)
			{
				return new ArrayMirror(this, a);
			}

			var f = obj as Scripting.Function;
			if (f != null)
			{
				return new FunctionMirror(f);
			}

			var o = obj as Scripting.Object;
			if (o != null)
			{
				if (o.InstanceOf(Context.Observable)) 
				{
					return new Observable(this, o, false);
				}
				else
				{
					return new ObjectMirror(this, o);	
				}
			}

			return null;
		}
	}
}
