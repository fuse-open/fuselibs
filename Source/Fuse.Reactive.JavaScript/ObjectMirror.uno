using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	partial class ObjectMirror : ValueMirror, IObservableObject, IMutable
	{
		Dictionary<string, object> _props = new Dictionary<string, object>();

		internal ObjectMirror(ThreadWorker worker, Scripting.Object obj): base(obj)
		{
			var k = obj.Keys;
			for (int i = 0; i < k.Length; i++)
			{
				var s = k[i];
				_props.Add(s, worker.Reflect(obj[s]));
			}
		}

		public override void Unsubscribe()
		{
			foreach (var p in _props)
			{
				var d = p.Value as ValueMirror;
				if (d != null) d.Unsubscribe();
			}
		}

		public bool ContainsKey(string key)
		{
			return _props.ContainsKey(key);
		}

		public object this[string key]
		{
			get { return _props[key]; }
		}

		public string[] Keys
		{
			get { return _props.Keys.ToArray(); }
		}
	}
}