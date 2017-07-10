using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	partial class ArrayMirror: ListMirror, IObservableArray, IMutable
	{
		object[] _items;

		internal ArrayMirror(ThreadWorker worker, Scripting.Array arr): base(arr)
		{
			_items = new object[arr.Length];
			for (int i = 0; i < _items.Length; i++)
				_items[i] = worker.Reflect(arr[i]);
		}

		internal object[] ItemsReadonly { get { return _items; } }

		public override void Unsubscribe()
		{
			for (int i = 0; i < _items.Length; i++)
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
			get { return _items.Length; }
		}
	}
}