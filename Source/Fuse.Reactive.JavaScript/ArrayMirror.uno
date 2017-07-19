using Uno.Collections;
using Uno;

namespace Fuse.Reactive
{
	partial class ArrayMirror: ListMirror, IObservableArray
	{
		List<object> _items;

		internal ArrayMirror(ThreadWorker worker, Scripting.Array arr): base(arr)
		{
			_items = new List<object>();
			for (int i = 0; i < arr.Length; i++)
				_items.Add(worker.Reflect(arr[i]));
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