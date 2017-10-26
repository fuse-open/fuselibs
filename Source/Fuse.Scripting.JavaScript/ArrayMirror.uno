using Uno.Collections;
using Uno;

namespace Fuse.Scripting.JavaScript
{
	class ArrayMirror: ListMirror, IArray
	{
		protected List<object> _items;

		/** Does not poulate the _props. This allows calling Set later with mirror == this */
		protected ArrayMirror(Scripting.Array obj) : base(obj) {}

		internal ArrayMirror(Scripting.Context context, IMirror mirror, Scripting.Array arr): base(arr)
		{
			Set(context, mirror, arr);
		}

		internal void Set(Scripting.Context context, IMirror mirror, Scripting.Array arr)
		{
			_items = new List<object>(arr.Length);
			for (int i = 0; i < arr.Length; i++) {
				_items.Add(mirror.Reflect(context, arr[i]));
			}
		}

		internal object[] ItemsReadonly { get { return _items.ToArray(); } }

		bool _hasUnsubscribed;
		public override void Unsubscribe()
		{
			if (_hasUnsubscribed) return;
			_hasUnsubscribed = true;

			for (int i = 0; i < _items.Count; i++)
			{
				var d = _items[i] as ValueMirror;
				if (d != null) d.Unsubscribe();
			}
		}

		public override object this[int index]
		{
			get { return _items[index]; }
		}

		public override int Length
		{
			get { return _items.Count; }
		}
	}
}
