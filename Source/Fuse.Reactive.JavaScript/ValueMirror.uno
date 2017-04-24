using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Reactive
{
	public abstract class ValueMirror: IRaw
	{
		public abstract void Unsubscribe();

		readonly object _raw;
		public object Raw { get { return _raw; } }

		protected ValueMirror(object raw)
		{
			_raw = raw;
		}

		public static void Unsubscribe(object obj)
		{
			var vm = obj as ValueMirror;
			if (vm != null) vm.Unsubscribe();
		}
	}

	public abstract class ListMirror: ValueMirror, IArray
	{
		public abstract int Length { get; }
		public abstract object this[int index] { get; }

		protected ListMirror(object raw) : base(raw) {}
	}
}