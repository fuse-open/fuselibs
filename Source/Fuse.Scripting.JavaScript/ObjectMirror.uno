using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	class ObjectMirror : ValueMirror, IObject
	{
		protected Dictionary<string, object> _props = new Dictionary<string, object>();

		/** Does not poulate the _props. This allows calling Set later with mirror == this */
		protected ObjectMirror(Scripting.Object obj) : base(obj) {}

		internal ObjectMirror(IMirror mirror, Scripting.Object obj): base(obj)
		{
			Set(mirror, obj);
		}

		internal virtual void Set(IMirror mirror, Scripting.Object obj)
		{
			_props.Clear();
			var k = obj.Keys;
			for (int i = 0; i < k.Length; i++)
			{
				var s = k[i];
				_props.Add(s, mirror.Reflect(obj[s]));
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