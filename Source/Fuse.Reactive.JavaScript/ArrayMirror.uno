using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	class ArrayMirror: ListMirror, IArray
	{
		protected List<object> _items;

		/** Does not poulate the _props. This allows calling Set later with mirror == this */
		protected ArrayMirror(Scripting.Array obj) : base(obj) {}

		internal ArrayMirror(IMirror mirror, Scripting.Array arr): base(arr)
		{
			Set(mirror, arr);
		}

		internal void Set(IMirror mirror, Scripting.Array arr)
		{
			_items = new List<object>(arr.Length);
			for (int i = 0; i < arr.Length; i++) {
				_items.Add(mirror.Reflect(arr[i]));
			}
		}

		internal object[] ItemsReadonly { get { return _items.ToArray(); } }

		public override void Unsubscribe()
		{
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