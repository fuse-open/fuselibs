using Uno.Collections;
using Uno;

namespace Fuse.Scripting.JavaScript
{
	class ObjectMirror : ValueMirror, IObject
	{
		protected Dictionary<string, object> _props = new Dictionary<string, object>();

		/** Does not poulate the _props. This allows calling Set later with mirror == this */
		protected ObjectMirror(Scripting.Object obj) : base(obj) {}

		internal ObjectMirror(Scripting.Context context, IMirror mirror, Scripting.Object obj): base(obj)
		{
			Set(context, mirror, obj);
		}

		internal virtual void Set(Scripting.Context context, IMirror mirror, Scripting.Object obj)
		{
			_props.Clear();
			var k = obj.Keys;
			for (int i = 0; i < k.Length; i++)
			{
				var s = k[i];
				_props.Add(s, mirror.Reflect(context, obj[s]));
			}
		}

		bool _hasUnsubscribed;
		public override void Unsubscribe()
		{
			if (_hasUnsubscribed) return;
			_hasUnsubscribed = true;

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
